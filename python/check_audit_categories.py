
import pandas as pd

# Load the audit dataset
audits = pd.read_csv("data/QualityAudits.csv")

# Count each discrepancy category, including missing values
print("Discrepancy category counts:")
print(audits["discrepancy_category"].value_counts(dropna=False))

# Count missing values
print("\nMissing category values:")
print(audits["discrepancy_category"].isna().sum())

# Compare audit results with missing categories
print("\nAudit result vs missing category:")
print(
    pd.crosstab(
        audits["result"],
        audits["discrepancy_category"].isna(),
        margins=True
    )
)
