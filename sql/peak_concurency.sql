WITH Events AS (
    -- Flatten starts and ends into a single stream
    SELECT start_time AS event_time, 1 AS delta
    FROM simulation_jobs
    
    UNION ALL
    
    SELECT end_time AS event_time, -1 AS delta
    FROM simulation_jobs
),
RunningTotal AS (
    SELECT 
        event_time,
        -- The explicit Window Function
        SUM(delta) OVER (
            ORDER BY event_time ASC, delta DESC -- delta DESC puts +1 before -1
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS current_concurrency
    FROM Events
)
SELECT 
    MAX(current_concurrency) AS max_simultaneous_jobs
FROM RunningTotal;