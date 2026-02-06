import pandas as pd

# Example spending data with two budget groups
spend_data = {
    "date": pd.date_range("2026-01-01", periods=10).tolist() * 2,
    "group": ["marketing"] * 10 + ["engineering"] * 10,
    "spend": [100, 150, 200, 300, 250, 400, 150, 200, 100, 50,
              200, 300, 150, 100, 250, 200, 300, 150, 100, 200],
}
df = pd.DataFrame(spend_data)

# Budget table by group
budget_data = {
    "group": ["marketing", "engineering"],
    "total_budget": [1000, 1500],
}
budget_df = pd.DataFrame(budget_data)

# Calculate cumulative spending per group using groupby + cumsum
df = df.sort_values(["group", "date"])
df["cumulative_spend"] = df.groupby("group")["spend"].cumsum()

# Merge with budget table
df = df.merge(budget_df, on="group")

# Find the first day where cumulative spend exceeds budget for each group
df["over_budget"] = df["cumulative_spend"] > df["total_budget"]

# Get first over-budget day per group using sort + drop_duplicates
over_budget_df = df[df["over_budget"]].sort_values(["group", "date"])
over_budget_df["row_number"] = over_budget_df.groupby("group").cumcount()
first_over_budget = over_budget_df[over_budget_df["row_number"] == 0][["group", "date", "cumulative_spend", "total_budget"]]

# Alternative ways to get first row per group:
# 1. Using loc with boolean mask (same as above but explicit):
#    first_over_budget = over_budget_df.loc[over_budget_df["row_number"] == 0, ["group", "date", "cumulative_spend", "total_budget"]]
#
# 2. Using groupby + iloc:
#    first_over_budget = over_budget_df.groupby("group", as_index=False).apply(lambda x: x.iloc[0])
#
# 3. Using groupby + head(1):
#    first_over_budget = over_budget_df.groupby("group", as_index=False).head(1)
#
# 4. Using groupby + nth(0):
#    first_over_budget = over_budget_df.groupby("group", as_index=False).nth(0)
#
# 5. Using drop_duplicates:
#    first_over_budget = over_budget_df.drop_duplicates(subset="group", keep="first")
#
# 6. Using for loop with unique groups + iloc:
#    results = []
#    for group_name in df["group"].unique():
#        group_df = df[(df["group"] == group_name) & (df["over_budget"])].sort_values("date")
#        if not group_df.empty:
#            results.append(group_df.iloc[0])
#    first_over_budget = pd.DataFrame(results)[["group", "date", "cumulative_spend", "total_budget"]]

print("First day budget exceeded per group:")
print(first_over_budget)
