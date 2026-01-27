/*
Expected table structure (denormalized job table):
+----------+---------------------+---------------------+---------------------+--------+
| job_id   | submission_time     | start_time          | end_time            | status |
+----------+---------------------+---------------------+---------------------+--------+
| 1001     | 2025-01-24 10:00:00 | 2025-01-24 10:02:30 | 2025-01-24 10:15:00 | done   |
| 1002     | 2025-01-24 10:01:00 | 2025-01-24 10:05:00 | 2025-01-24 10:20:00 | done   |
+----------+---------------------+---------------------+---------------------+--------+
*/

-- Calculate λ (lambda): Arrival rate per hour for last 30 days
WITH hourly_arrivals AS (
    SELECT 
        TIMESTAMP_TRUNC(submission_time, HOUR) AS hour,
        COUNT(job_id) AS jobs_per_hour
    FROM 
        job_logs
    WHERE 
        submission_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
        AND submission_time IS NOT NULL
    GROUP BY 1
)
SELECT 
    hour,
    jobs_per_hour
FROM hourly_arrivals
ORDER BY hour DESC;


-- Calculate average λ (lambda) across all hours
WITH hourly_arrivals AS (
    SELECT 
        TIMESTAMP_TRUNC(submission_time, HOUR) AS hour,
        COUNT(job_id) AS jobs_per_hour
    FROM 
        job_logs
    WHERE 
        submission_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
        AND submission_time IS NOT NULL
    GROUP BY 1
)
SELECT 
    COUNT(*) AS total_hours,
    SUM(jobs_per_hour) AS total_jobs,
    AVG(jobs_per_hour) AS lambda_avg_jobs_per_hour,
    MIN(jobs_per_hour) AS lambda_min,
    MAX(jobs_per_hour) AS lambda_max
FROM hourly_arrivals;
