/* 
Calculate the Coefficient of Variation (Ca) of the arrival gap 
for queueing theory analysis
*/

WITH ArrivalGaps AS (
    SELECT 
        LAG(submitted_at) OVER (ORDER BY submitted_at) AS prev_t,
        submitted_at AS curr_t
    FROM job_logs
),
Stats AS (
    SELECT 
        EXTRACT(EPOCH FROM (curr_t - prev_t)) AS diff
    FROM ArrivalGaps
    WHERE prev_t IS NOT NULL
)
SELECT 
    AVG(diff) AS mean_iat,
    STDDEV(diff) AS stddev_iat,
    -- This is your Ca (Coefficient of Variation)
    STDDEV(diff) / NULLIF(AVG(diff), 0) AS ca_burstiness_score
FROM Stats;