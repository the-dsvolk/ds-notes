WITH job_times AS (
    SELECT
        job_id,
        MAX(IF(event = 'submitted', event_time, NULL)) AS submission_time,
        MAX(IF(event = 'started', event_time, NULL)) AS start_time
    FROM job_events
    GROUP BY job_id
)