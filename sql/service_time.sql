SELECT 
    COUNT(job_id) as completed_jobs,
    AVG(EXTRACT(EPOCH FROM (end_time - start_time))/3600) as avg_service_time_hours,
    -- Also calculate variance for C_s²
    VARIANCE(EXTRACT(EPOCH FROM (end_time - start_time))/3600) as variance_service_time,
    STDDEV(EXTRACT(EPOCH FROM (end_time - start_time))/3600) as stddev_service_time
FROM job_logs
WHERE status = 'COMPLETED'
  AND start_time IS NOT NULL 
  AND end_time IS NOT NULL
  AND end_time > start_time
  AND start_time >= NOW() - INTERVAL '30 days';