import numpy as np
import pandas as pd
import os

rng = np.random.default_rng(42)
os.makedirs("data", exist_ok=True)

# 1. Create 60 contributors
N = 60
ids = [f"C{i:03d}" for i in range(1, N + 1)]

contrib = pd.DataFrame({
    "contributor_id": ids,
    "group": rng.choice(["Group A", "Group B", "Group C"], N),
    "join_date": (
        pd.Timestamp("2026-01-05")
        + pd.to_timedelta(rng.integers(0, 120, N), "D")
    )
})

skill = dict(zip(ids, rng.normal(0, 1, N)))

# 2. Create the working dates
days = pd.bdate_range("2026-07-06", "2026-09-25")

# 3. Create attendance records
att = pd.DataFrame(
    [(c, d) for c in ids for d in days],
    columns=["contributor_id", "date"]
)

att["status"] = rng.choice(
    ["Present", "Leave", "Absent"],
    len(att),
    p=[0.88, 0.06, 0.06]
)

att["leave_applied"] = np.where(
    att.status == "Leave",
    rng.random(len(att)) < 0.9,
    np.where(
        att.status == "Absent",
        rng.random(len(att)) < 0.15,
        False
    )
)

att["timesheet_filled"] = np.where(
    att.status == "Present",
    rng.random(len(att)) < 0.92,
    False
)

# 4. Create task records
cats = [
    "Relevance", "Accuracy", "Timeliness",
    "Image-Text Match", "Formatting"
]

base_min = {
    "Relevance": 6,
    "Accuracy": 9,
    "Timeliness": 7,
    "Image-Text Match": 8,
    "Formatting": 4
}

rows = []
tid = 1

for c, d in att[att.status == "Present"][
    ["contributor_id", "date"]
].itertuples(index=False):

    t = pd.Timestamp(d) + pd.Timedelta(
        hours=9, minutes=int(rng.integers(0, 30))
    )

    for _ in range(rng.poisson(22)):
        cat = rng.choice(cats)
        dur = float(rng.lognormal(np.log(base_min[cat]), 0.35))
        end = t + pd.Timedelta(minutes=dur)

        rows.append((f"T{tid:06d}", c, cat, t, end, round(dur, 1)))
        tid += 1

        t = end + pd.Timedelta(minutes=int(rng.integers(1, 6)))

tasks = pd.DataFrame(
    rows,
    columns=[
        "task_id", "contributor_id", "category",
        "start_ts", "end_ts", "duration_min"
    ]
)

tasks["task_date"] = tasks.start_ts.dt.normalize()

# 5. Create training records
weak = sorted(ids, key=lambda x: skill[x])[:35]
trained = rng.choice(weak, 24, replace=False)

tr = pd.DataFrame({
    "contributor_id": trained,
    "module": rng.choice([
        "Guideline Refresher",
        "Edge-Case Workshop",
        "Calibration Session"
    ], 24),
    "training_date": [
        pd.Timestamp("2026-08-03")
        + pd.Timedelta(days=int(x))
        for x in rng.integers(0, 21, 24)
    ]
})

tr_date = dict(zip(tr.contributor_id, tr.training_date))

# 6. Create quality audit records
cat_eff = {
    "Relevance": 0,
    "Accuracy": 0.06,
    "Timeliness": 0.03,
    "Image-Text Match": 0.04,
    "Formatting": -0.03
}

disc = [
    "Guideline misread",
    "Missed evidence",
    "Wrong label",
    "Incomplete rationale",
    "Inconsistent judgment"
]

aud = []

for atype, frac in [("QA", 0.15), ("LR", 0.08)]:
    s = tasks.sample(
        frac=frac,
        random_state=1 if atype == "QA" else 2
    ).copy()

    s["audit_type"] = atype

    aud.append(
        s[[
            "task_id", "contributor_id", "category",
            "task_date", "audit_type"
        ]]
    )

aud = pd.concat(aud, ignore_index=True)

post = aud.apply(
    lambda r: (
        r.contributor_id in tr_date
        and r.task_date >= tr_date[r.contributor_id]
    ),
    axis=1
)

p = (
    0.26
    - 0.05 * aud.contributor_id.map(skill)
    + aud.category.map(cat_eff)
    - 0.05 * post
).clip(0.02, 0.6)

err = rng.random(len(aud)) < p

aud["dent_points"] = np.where(
    err,
    rng.choice([5, 10, 20, 40], len(aud), p=[0.4, 0.3, 0.2, 0.1]),
    0
)

aud["score"] = 100 - aud.dent_points
aud["result"] = np.where(aud.score < 90, "Fail", "Pass")

aud["discrepancy_category"] = np.where(
    err,
    rng.choice(disc, len(aud)),
    "None"
)

aud.insert(
    0, "audit_id",
    [f"A{i:06d}" for i in range(1, len(aud) + 1)]
)

# 7. Create defect and issue-resolution records
team = rng.choice(ids, 20, replace=False)
n = 1500

topic = rng.choice(
    ["Accuracy", "Timeliness", "Legibility", "Layout"],
    n,
    p=[0.3, 0.2, 0.25, 0.25]
)

opened = (
    pd.Timestamp("2026-07-06 09:00")
    + pd.to_timedelta(rng.integers(0, 80 * 24 * 60, n), "min")
)

res = rng.lognormal(np.log(35), 0.6, n)

defects = pd.DataFrame({
    "defect_id": [f"D{i:05d}" for i in range(1, n + 1)],
    "contributor_id": rng.choice(team, n),
    "defect_type": rng.choice(
        ["Image Text", "UI Issue"], n, p=[0.55, 0.45]
    ),
    "bucket_tier": rng.choice(
        ["Tier A (internal pilot)", "Tier B (early access)"],
        n, p=[0.45, 0.55]
    ),
    "topic_bucket": topic,
    "watchlist_added": rng.random(n) < np.where(
        np.isin(topic, ["Accuracy", "Timeliness"]), 0.35, 0.12
    ),
    "opened_ts": opened,
    "resolved_ts": opened + pd.to_timedelta(res, "min"),
    "resolution_min": res.round(1)
})

# 8. Save the six CSV files
datasets = {
    "Contributors": contrib,
    "Attendance": att,
    "Tasks": tasks,
    "QualityAudits": aud.drop(
        columns=["category", "task_date", "contributor_id"]
    ),
    "TrainingRecords": tr,
    "Defects": defects
}

for name, df in datasets.items():
    df.to_csv(f"data/{name}.csv", index=False)
    print(f"{name}.csv: {len(df):,} rows, {len(df.columns)} columns")

print("\nAll six datasets generated successfully.")