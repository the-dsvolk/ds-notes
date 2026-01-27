/* 
Write a BigQuery SQL query to identify the Daily Count of Safety-Critical Jobs that waited more than 10 minutes to start, 
during periods where the cluster was at >95% utilization.
The Schema: sim_infrastructure.job_logs
Column Type Description 
job_id STRING Unique ID 
priority INT641 (Safety-Critical), 2 (Standard), 3 (Low/Research)
submission_time TIMESTAMP When the user clicked "Run"
start_time TIMESTAMP When a GPU actually became available
gpu_slots INT6 4Number of GPUs required for this job
The Goal:
 Find the "Preemption Gap"Calculate the concurrency at the time of each job's submission.
 Filter for Safety-Critical jobs (Priority 1) that waited >600 seconds.
 Identify if the cluster was "Saturated" (>4,750 GPUs used) at the time they were waiting.
*/
    -- Step 1: Standard Concurrency Pattern
    SELECT 
        event_time,
        SUM(delta) OVER (
            ORDER BY event_time ASC, delta DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS active_gpus
    FROM (
        SELECT start_time AS event_time, gpu_slots AS delta FROM `sim_infrastructure.job_logs`
        UNION ALL
        SELECT end_time AS event_time, -gpu_slots AS delta FROM `sim_infrastructure.job_logs`
    )
),
JobWaitAudit AS (
    -- Step 2: Join jobs to the concurrency state at the time of their submission
    SELECT 
        j.job_id,
        DATE(j.submission_time) AS usage_date,
        j.priority,
        TIMESTAMP_DIFF(j.start_time, j.submission_time, SECOND) AS wait_seconds,
        -- Get the cluster state at the exact moment of submission
        (SELECT MAX(active_gpus) 
         FROM ConcurrencyTimeline c 
         WHERE c.event_time <= j.submission_time) AS cluster_load_at_submission
    FROM `sim_infrastructure.job_logs` j
    WHERE j.priority = 1 -- Only Safety-Critical
)
-- Step 3: Final Aggregation for Leadership
SELECT 
    usage_date,
    COUNTIF(wait_seconds > 600 AND cluster_load_at_submission >= 4750) AS starved_safety_jobs,
    ROUND(AVG(wait_seconds) / 60, 2) AS avg_wait_mins_for_starved_jobs
FROM JobWaitAudit
GROUP BY 1
ORDER BY 1 DESC;