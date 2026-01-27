/*
Quiet Hours Analysis
Find time periods with low utilization for batch jobs, maintenance, or capacity planning.

Expected table structure (job logs):
+----------+---------------------+---------------------+--------+
| job_id   | start_time          | end_time            | gpus   |
+----------+---------------------+---------------------+--------+
| 1001     | 2025-01-24 10:00:00 | 2025-01-24 10:30:00 | 8      |
| 1002     | 2025-01-24 10:15:00 | 2025-01-24 11:00:00 | 4      |
+----------+---------------------+---------------------+--------+
*/

-- Generate hourly time spine for last 30 days
WITH time_spine AS (
    SELECT hour
    FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY(
            TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY),
            CURRENT_TIMESTAMP(),
            INTERVAL 1 HOUR
        )
    ) AS hour
),

-- Count jobs running during each hour
hourly_usage AS (
    SELECT
        TIMESTAMP_TRUNC(start_time, HOUR) AS hour,
        COUNT(*) AS jobs_running,
        SUM(gpus) AS gpus_in_use
    FROM job_logs
    WHERE start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    GROUP BY 1
),

-- Join to time spine (includes hours with zero activity)
hourly_stats AS (
    SELECT
        ts.hour,
        EXTRACT(HOUR FROM ts.hour) AS hour_of_day,
        EXTRACT(DAYOFWEEK FROM ts.hour) AS day_of_week,  -- 1=Sunday, 7=Saturday
        COALESCE(hu.jobs_running, 0) AS jobs_running,
        COALESCE(hu.gpus_in_use, 0) AS gpus_in_use
    FROM time_spine ts
    LEFT JOIN hourly_usage hu ON ts.hour = hu.hour
)

-- Find quiet hours pattern by hour of day and day of week
SELECT
    hour_of_day,
    CASE day_of_week
        WHEN 1 THEN 'Sun'
        WHEN 2 THEN 'Mon'
        WHEN 3 THEN 'Tue'
        WHEN 4 THEN 'Wed'
        WHEN 5 THEN 'Thu'
        WHEN 6 THEN 'Fri'
        WHEN 7 THEN 'Sat'
    END AS day_name,
    AVG(jobs_running) AS avg_jobs,
    AVG(gpus_in_use) AS avg_gpus,
    CASE 
        WHEN AVG(gpus_in_use) < 200 THEN '🟢 quiet'
        WHEN AVG(gpus_in_use) < 500 THEN '🟡 normal'
        ELSE '🔴 busy'
    END AS utilization_band
FROM hourly_stats
GROUP BY hour_of_day, day_of_week, day_name
ORDER BY day_of_week, hour_of_day;


/*
Alternative: Find specific quiet hour windows (consecutive low-utilization hours)
*/

WITH time_spine AS (
    SELECT hour
    FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY(
            TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY),
            CURRENT_TIMESTAMP(),
            INTERVAL 1 HOUR
        )
    ) AS hour
),
hourly_usage AS (
    SELECT
        TIMESTAMP_TRUNC(start_time, HOUR) AS hour,
        SUM(gpus) AS gpus_in_use
    FROM job_logs
    WHERE start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    GROUP BY 1
),
with_utilization AS (
    SELECT
        ts.hour,
        COALESCE(hu.gpus_in_use, 0) AS gpus_in_use,
        COALESCE(hu.gpus_in_use, 0) < 200 AS is_quiet  -- Threshold: 200 GPUs
    FROM time_spine ts
    LEFT JOIN hourly_usage hu ON ts.hour = hu.hour
)
SELECT
    hour,
    gpus_in_use,
    is_quiet
FROM with_utilization
WHERE is_quiet = TRUE
ORDER BY hour;
