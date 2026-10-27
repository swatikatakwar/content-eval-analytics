from pathlib import Path
import pandas as pd

# 1. Locate the data folder relative to the project root
DATA_DIR = Path("data")

# 2. Define the columns expected in each file
expected_columns = {
    "Contributors": [
        "contributor_id", "group", "join_date"
    ],
    "Attendance": [
        "contributor_id", "date", "status",
        "leave_applied", "timesheet_filled"
    ],
    "Tasks": [
        "task_id", "contributor_id", "category",
        "start_ts", "end_ts", "duration_min", "task_date"
    ],
    "QualityAudits": [
        "audit_id", "task_id", "audit_type",
        "dent_points", "score", "result",
        "discrepancy_category"
    ],
    "TrainingRecords": [
        "contributor_id", "module", "training_date"
    ],
    "Defects": [
        "defect_id", "contributor_id", "defect_type",
        "bucket_tier", "topic_bucket", "watchlist_added",
        "opened_ts", "resolved_ts", "resolution_min"
    ]
}

# 3. Load all six CSV files
tables = {}

print("=" * 60)
print("CONTENT EVALUATION ANALYTICS - DATA VALIDATION")
print("=" * 60)

for name, columns in expected_columns.items():
    path = DATA_DIR / f"{name}.csv"

    if not path.exists():
        print(f"\nERROR: Missing file: {path}")
        continue

    df = pd.read_csv(path)
    tables[name] = df

    print(f"\n{name}.csv")
    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns)}")
    print(f"Column names correct: {set(df.columns) == set(columns)}")

    missing_columns = set(columns) - set(df.columns)
    extra_columns = set(df.columns) - set(columns)

    if missing_columns:
        print("Missing columns:", sorted(missing_columns))

    if extra_columns:
        print("Unexpected columns:", sorted(extra_columns))

# Stop if any file is missing or has the wrong structure.
if len(tables) != len(expected_columns):
    raise SystemExit("\nFix missing files before continuing.")

if any(
    set(tables[name].columns) != set(columns)
    for name, columns in expected_columns.items()
):
    raise SystemExit("\nFix column names before continuing.")

# 4. Check missing values and duplicate records
print("\n" + "=" * 60)
print("MISSING VALUES AND DUPLICATES")
print("=" * 60)

for name, df in tables.items():
    print(f"\n{name}")
    print("Total missing cells:", int(df.isna().sum().sum()))
    print("Completely duplicated rows:", int(df.duplicated().sum()))

    missing_by_column = df.isna().sum()
    if missing_by_column.any():
        print("Missing values by column:")
        print(missing_by_column[missing_by_column > 0])

# 5. Check identifiers that should be unique
print("\n" + "=" * 60)
print("UNIQUE ID CHECKS")
print("=" * 60)

unique_ids = {
    "Contributors": "contributor_id",
    "Tasks": "task_id",
    "QualityAudits": "audit_id",
    "Defects": "defect_id"
}

for name, column in unique_ids.items():
    df = tables[name]
    count = int(df[column].duplicated().sum())
    print(f"{name}.{column}: duplicate IDs = {count}")

# 6. Check allowed values and business rules
print("\n" + "=" * 60)
print("BUSINESS RULE CHECKS")
print("=" * 60)

def report_count(label, count):
    print(f"{label}: {int(count)}")

c = tables["Contributors"]
a = tables["Attendance"]
t = tables["Tasks"]
q = tables["QualityAudits"]
tr = tables["TrainingRecords"]
d = tables["Defects"]

report_count(
    "Invalid attendance statuses",
    (~a["status"].isin(["Present", "Absent", "Leave"])).sum()
)

report_count(
    "Invalid task categories",
    (~t["category"].isin([
        "Relevance", "Accuracy", "Timeliness",
        "Image-Text Match", "Formatting"
    ])).sum()
)

report_count(
    "Invalid audit types",
    (~q["audit_type"].isin(["LR", "QA"])).sum()
)

report_count(
    "Invalid dent values",
    (~q["dent_points"].isin([0, 5, 10, 20, 40])).sum()
)

report_count(
    "Scores inconsistent with dent points",
    (q["score"] != 100 - q["dent_points"]).sum()
)

report_count(
    "Pass/fail results inconsistent with score",
    (
        q["result"] != q["score"].lt(90).map(
            {True: "Fail", False: "Pass"}
        )
    ).sum()
)

report_count(
    "Invalid task durations",
    (t["duration_min"] <= 0).sum()
)

report_count(
    "Task end before task start",
    (pd.to_datetime(t["end_ts"]) < pd.to_datetime(t["start_ts"])).sum()
)

report_count(
    "Invalid resolution durations",
    (d["resolution_min"] <= 0).sum()
)

report_count(
    "Resolution timestamp before opening timestamp",
    (pd.to_datetime(d["resolved_ts"]) < pd.to_datetime(d["opened_ts"])).sum()
)

report_count(
    "Attendance records with timesheets filled while not present",
    ((a["status"] != "Present") & a["timesheet_filled"].eq(True)).sum()
)


# 7. Check relationships between tables
print("\n" + "=" * 60)
print("RELATIONSHIP CHECKS")
print("=" * 60)

contributor_ids = set(c["contributor_id"])
task_ids = set(t["task_id"])

report_count(
    "Attendance rows with unknown contributors",
    (~a["contributor_id"].isin(contributor_ids)).sum()
)

report_count(
    "Task rows with unknown contributors",
    (~t["contributor_id"].isin(contributor_ids)).sum()
)

report_count(
    "Training rows with unknown contributors",
    (~tr["contributor_id"].isin(contributor_ids)).sum()
)

report_count(
    "Defect rows with unknown contributors",
    (~d["contributor_id"].isin(contributor_ids)).sum()
)

report_count(
    "Audit rows with unknown tasks",
    (~q["task_id"].isin(task_ids)).sum()
)

report_count(
    "Attendance duplicate contributor-date pairs",
    a.duplicated(["contributor_id", "date"]).sum()
)

# 8. Check dates, numeric values, and remaining categories
print("\n" + "=" * 60)
print("DATE AND DATA TYPE CHECKS")
print("=" * 60)

date_columns = {
    "Contributors": ["join_date"],
    "Attendance": ["date"],
    "Tasks": ["start_ts", "end_ts", "task_date"],
    "QualityAudits": [],
    "TrainingRecords": ["training_date"],
    "Defects": ["opened_ts", "resolved_ts"]
}

for name, columns in date_columns.items():
    df = tables[name]

    for column in columns:
        parsed = pd.to_datetime(df[column], errors="coerce")
        report_count(
            f"{name}.{column} invalid dates",
            parsed.isna().sum()
        )

report_count(
    "Invalid contributor groups",
    (~c["group"].isin(["Group A", "Group B", "Group C"])).sum()
)

report_count(
    "Invalid training modules",
    (~tr["module"].isin([
        "Guideline Refresher",
        "Edge-Case Workshop",
        "Calibration Session"
    ])).sum()
)

report_count(
    "Invalid defect types",
    (~d["defect_type"].isin(["Image Text", "UI Issue"])).sum()
)

report_count(
    "Invalid defect topics",
    (~d["topic_bucket"].isin([
        "Accuracy", "Timeliness", "Legibility", "Layout"
    ])).sum()
)

report_count(
    "Invalid watchlist values",
    (~d["watchlist_added"].isin([True, False])).sum()
)

# 9. Final summary


# Check failed audits with missing discrepancy categories
audit_file = pd.read_csv(
    "data/QualityAudits.csv",
    keep_default_na=False
)

failed_audits_missing_category = (
    (audit_file["result"] == "Fail")
    & (audit_file["discrepancy_category"] == "")
).sum()

print(
    "Failed audits with missing discrepancy category:",
    failed_audits_missing_category
)

# 8. Final summary
print("\n" + "=" * 60)
print("VALIDATION SCRIPT FINISHED")
print("=" * 60)
print("Review every reported count before importing into SQL Server.")


 