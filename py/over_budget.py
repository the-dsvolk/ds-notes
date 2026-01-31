import pandas as pd

# Example data
data = {
    "date": pd.date_range("2026-01-01", periods=10),
    "spend": [100, 150, 200, 300, 250, 400, 150, 200, 100, 50],
}
df = pd.DataFrame(data)

total_budget = 1000

# Calculate cumulative spending
df["cumulative_spend"] = df["spend"].cumsum()

# Find the first day where cumulative spend exceeds budget
budget_exceeded = df[df["cumulative_spend"] > total_budget]

if not budget_exceeded.empty:
    out_of_budget_day = budget_exceeded.iloc[0]["date"]
    print(f"Budget runs out on: {out_of_budget_day}")
else:
    print("Budget not exceeded within the period")
