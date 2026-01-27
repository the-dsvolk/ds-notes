/*
Expected table structure (denormalized job table):
+----------+---------------------+---------------------+---------------------+--------+
| job_id   | submission_time     | start_time          | end_time            | status |
+----------+---------------------+---------------------+---------------------+--------+
| 1001     | 2025-01-24 10:00:00 | 2025-01-24 10:02:30 | 2025-01-24 10:15:00 | done   |
| 1002     | 2025-01-24 10:01:00 | 2025-01-24 10:05:00 | 2025-01-24 10:20:00 | done   |
+----------+---------------------+---------------------+---------------------+--------+
*/
SELECT
    DATE(submission_time) AS usage_date,
    -- APPROX_QUANTILES returns an ARRAY of N elements. 
    -- [OFFSET(95)] extracts the 95th element from a 101-element array (0-100).
    APPROX_QUANTILES(TIMESTAMP_DIFF(start_time, submission_time, SECOND), 100)[OFFSET(95)] AS p95_wait_seconds,
    COUNT(*) AS total_jobs
FROM 
    `waymo-project.infrastructure.simulation_jobs`
WHERE 
    submission_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY 
    1
ORDER BY 
    1 DESC;


/*
Expected table structure (event log table):
+----------+-----------+---------------------+
| job_id   | event     | event_time          |
+----------+-----------+---------------------+
| 1001     | submitted | 2025-01-24 10:00:00 |
| 1001     | started   | 2025-01-24 10:02:30 |
| 1001     | completed | 2025-01-24 10:15:00 |
| 1002     | submitted | 2025-01-24 10:01:00 |
| 1002     | started   | 2025-01-24 10:05:00 |
+----------+-----------+---------------------+
*/
WITH job_times AS (
    SELECT
        job_id,
        MAX(IF(event = 'submitted', event_time, NULL)) AS submission_time,
        MAX(IF(event = 'started', event_time, NULL)) AS start_time
    FROM job_events
    GROUP BY job_id
)
SELECT
    DATE(submission_time) AS usage_date,
    APPROX_QUANTILES(TIMESTAMP_DIFF(start_time, submission_time, SECOND), 100)[OFFSET(95)] AS p95_wait_seconds,
    COUNT(*) AS total_jobs
FROM job_times
WHERE 
    submission_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    AND start_time IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;