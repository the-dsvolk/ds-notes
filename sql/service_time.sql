SELECT 
    COUNT(job_id) as completed_jobs,
    AVG(TIMESTAMP_DIFF(end_time, start_time, SECOND) / 3600.0) as avg_service_time_hours,
    -- Also calculate variance for C_s²
    VARIANCE(TIMESTAMP_DIFF(end_time, start_time, SECOND) / 3600.0) as variance_service_time,
    STDDEV(TIMESTAMP_DIFF(end_time, start_time, SECOND) / 3600.0) as stddev_service_time
FROM job_logs
WHERE status = 'COMPLETED'
  AND start_time IS NOT NULL 
  AND end_time IS NOT NULL
  AND end_time > start_time
  AND start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);