# 1. Calculate a rolling mean and standard deviation
window = 4  # Look at the last month of data
rolling_mean = df["executions"].rolling(window=window).mean()
rolling_std = df["executions"].rolling(window=window).std()

# 2. Calculate Z-Score
df["z_score"] = (df["executions"] - rolling_mean) / rolling_std

# 3. Identify outliers (typically a Z-score > 2 or < -2)
change_points = df[df["z_score"].abs() > 2]
print(change_points[["executions", "z_score"]])
