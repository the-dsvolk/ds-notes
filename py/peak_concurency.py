import pandas as pd

# Sample Data: Simulation job start and end times
data = {
    "job_id": [1, 2, 3, 4, 5],
    "start_time": pd.to_datetime(
        [
            "2026-01-23 10:00:00",
            "2026-01-23 10:05:00",
            "2026-01-23 10:02:00",
            "2026-01-23 10:15:00",
            "2026-01-23 10:10:00",
        ]
    ),
    "end_time": pd.to_datetime(
        [
            "2026-01-23 10:10:00",
            "2026-01-23 10:20:00",
            "2026-01-23 10:08:00",
            "2026-01-23 10:30:00",
            "2026-01-23 10:25:00",
        ]
    ),
}
df = pd.DataFrame(data)

# Step 1: Create 'Start' and 'End' events
starts = pd.DataFrame({"time": df["start_time"], "delta": 1})
ends = pd.DataFrame({"time": df["end_time"], "delta": -1})

# Step 2: Concatenate and Sort
# We sort by time. If times are tied, we sort by delta descending (starts before ends)
timeline = pd.concat([starts, ends]).sort_values(
    by=["time", "delta"], ascending=[True, False]
)

# Step 3: Compute Cumulative Sum (The equivalent of a Window Function)
timeline["concurrency"] = timeline["delta"].cumsum()

# Step 4: Extract the Maximum
peak_concurrency = timeline["concurrency"].max()

print(f"Peak Concurrency: {peak_concurrency}")
