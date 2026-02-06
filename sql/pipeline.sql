-- ============================================================================
-- ETL Pipeline for Multi-Cluster Compute Utilization Tracking
-- ============================================================================
-- Interview Topic: Design ETL pipeline and key tables for tracking/modeling
-- utilization in a multi-cluster compute environment (BigQuery/Spark)
-- ============================================================================

-- ============================================================================
-- LAYER 1: SOURCE TABLES (Bronze Layer)
-- Ingested from cluster event logs, metrics collectors, schedulers
-- ============================================================================

-- Job definitions (one row per job, immutable after submission)
CREATE TABLE src.jobs (
    job_id STRING,
    cluster_id STRING,
    user_id STRING,
    queue_name STRING,
    priority INT64,
    
    -- Resource requests (defined at submission time)
    requested_cpu_cores FLOAT64,
    requested_memory_gb FLOAT64,
    requested_gpu_count INT64,
    gpu_type STRING,
    
    -- Metadata
    job_name STRING,
    job_type STRING,  -- 'batch', 'interactive', 'training', 'inference'
    submit_timestamp TIMESTAMP,
    raw_payload STRING,  -- Original JSON for debugging
    ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(submit_timestamp)
CLUSTER BY cluster_id, job_id;

-- Job events (multiple rows per job, state transitions)
CREATE TABLE src.job_events (
    event_id STRING,
    job_id STRING,
    event_timestamp TIMESTAMP,
    event_type STRING,  -- 'SUBMITTED', 'PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'KILLED'
    exit_code INT64,    -- Only populated for terminal events
    failure_reason STRING,  -- Only populated for FAILED events
    ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY job_id;

-- Resource metrics from Prometheus/Chronosphere (scraped every 10 minutes)
-- 6 samples per hour per node, ~144 samples per day per node
CREATE TABLE src.node_metrics (
    metric_timestamp TIMESTAMP,
    cluster_id STRING,
    node_id STRING,
    node_type STRING,  -- 'cpu-only', 'gpu-a100', 'gpu-v100', etc.
    total_cpu_cores INT64,
    used_cpu_cores FLOAT64,
    total_memory_gb FLOAT64,
    used_memory_gb FLOAT64,
    total_gpu_count INT64,
    used_gpu_count INT64,
    gpu_utilization_pct FLOAT64,  -- Average GPU compute utilization
    ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(metric_timestamp)
CLUSTER BY cluster_id, node_id;

-- Job-to-node allocations (links jobs to nodes they run on)
-- Critical for distributed/multi-node jobs (e.g., distributed training, Spark)
CREATE TABLE src.job_node_allocations (
    allocation_id STRING,
    job_id STRING,
    node_id STRING,
    cluster_id STRING,
    
    -- Allocation lifecycle
    allocation_start TIMESTAMP,  -- When job was scheduled to this node
    allocation_end TIMESTAMP,    -- When job released this node (NULL if still running)
    
    -- Resources allocated on THIS node (for multi-node jobs, each node gets a portion)
    allocated_cpu_cores FLOAT64,
    allocated_memory_gb FLOAT64,
    allocated_gpu_count INT64,
    gpu_device_ids ARRAY<INT64>,  -- Specific GPU indices: [0, 1, 2, 3]
    
    -- Role in distributed job
    node_role STRING,  -- 'master', 'worker', 'parameter_server', 'single' (for non-distributed)
    node_rank INT64,   -- 0, 1, 2... for distributed training
    
    ingestion_timestamp TIMESTAMP
)
PARTITION BY DATE(allocation_start)
CLUSTER BY job_id, node_id;

-- Cluster configuration snapshots (daily)
CREATE TABLE src.cluster_config (
    snapshot_date DATE,
    cluster_id STRING,
    cluster_name STRING,
    region STRING,
    total_nodes INT64,
    total_cpu_cores INT64,
    total_memory_gb FLOAT64,
    total_gpus INT64,
    gpu_types ARRAY<STRING>,
    is_preemptible BOOLEAN,
    cost_per_hour_usd FLOAT64
);


-- ============================================================================
-- LAYER 2: STAGING/CLEANED TABLES (Silver Layer)
-- Deduplicated, validated, normalized
-- ============================================================================

-- Staging: Validated jobs (job_id is unique primary key)
CREATE TABLE staging.jobs_cleaned AS
SELECT
    job_id,
    cluster_id,
    user_id,
    COALESCE(queue_name, 'default') AS queue_name,
    COALESCE(priority, 0) AS priority,
    COALESCE(requested_cpu_cores, 0) AS requested_cpu_cores,
    COALESCE(requested_memory_gb, 0) AS requested_memory_gb,
    COALESCE(requested_gpu_count, 0) AS requested_gpu_count,
    COALESCE(gpu_type, 'none') AS gpu_type,
    job_name,
    job_type,
    submit_timestamp
FROM src.jobs
WHERE job_id IS NOT NULL;
-- Note: If source has duplicates (re-ingestion, corrections), add:
-- QUALIFY ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY ingestion_timestamp DESC) = 1

-- Staging: Validated job events (event_id is unique primary key)
CREATE TABLE staging.job_events_cleaned AS
SELECT
    event_id,
    job_id,
    event_timestamp,
    event_type,
    exit_code,
    failure_reason
FROM src.job_events
WHERE event_id IS NOT NULL
  AND job_id IS NOT NULL;
-- Note: If source has duplicates, add:
-- QUALIFY ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY ingestion_timestamp DESC) = 1


-- ============================================================================
-- LAYER 3: DIMENSION TABLES (Silver Layer)
-- Slowly changing dimensions for lookups
-- ============================================================================

-- Dimension: Clusters
CREATE TABLE dim.clusters (
    cluster_key INT64,  -- Surrogate key
    cluster_id STRING,  -- Natural key
    cluster_name STRING,
    region STRING,
    cloud_provider STRING,
    cluster_type STRING,  -- 'on-demand', 'preemptible', 'reserved'
    effective_from DATE,
    effective_to DATE,
    is_current BOOLEAN
);

-- Dimension: Users
CREATE TABLE dim.users (
    user_key INT64,
    user_id STRING,
    team STRING,
    department STRING,
    cost_center STRING,
    is_active BOOLEAN
);

-- Dimension: Time (pre-populated calendar)
CREATE TABLE dim.time (
    date_key INT64,
    full_date DATE,
    year INT64,
    quarter INT64,
    month INT64,
    week_of_year INT64,
    day_of_week INT64,
    day_name STRING,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN
);


-- ============================================================================
-- LAYER 4: FACT TABLES (Gold Layer)
-- Core business events at grain level
-- ============================================================================

-- Fact: Job executions (one row per completed job)
-- Schema:
--   job_id, cluster_id, user_id, queue_name     -- identifiers
--   submit_time, start_time, end_time           -- timestamps
--   wait_time_seconds, run_time_seconds         -- durations (derived)
--   requested_cpu/memory/gpu                    -- resource requests (from jobs)
--   exit_status, exit_code                      -- outcome (from events)
--   cpu_seconds, gpu_seconds                    -- consumption (derived)
--
-- Build by joining jobs (definitions) with pivoted events (timestamps)
CREATE OR REPLACE TABLE fact.job_executions AS
WITH events_pivoted AS (
    -- Pivot events to get one row per job with all timestamps
    SELECT
        job_id,
        MAX(CASE WHEN event_type = 'SUBMITTED' THEN event_timestamp END) AS submit_time,
        MAX(CASE WHEN event_type = 'RUNNING' THEN event_timestamp END) AS start_time,
        MAX(CASE WHEN event_type IN ('COMPLETED', 'FAILED', 'KILLED') THEN event_timestamp END) AS end_time,
        MAX(CASE WHEN event_type IN ('COMPLETED', 'FAILED', 'KILLED') THEN event_type END) AS exit_status,
        MAX(CASE WHEN event_type IN ('COMPLETED', 'FAILED', 'KILLED') THEN exit_code END) AS exit_code
    FROM staging.job_events_cleaned
    GROUP BY job_id
)
SELECT
    j.job_id,
    j.cluster_id,
    j.user_id,
    j.queue_name,
    
    -- Timestamps from events
    COALESCE(e.submit_time, j.submit_timestamp) AS submit_time,
    e.start_time,
    e.end_time,
    
    -- Durations
    TIMESTAMP_DIFF(e.start_time, COALESCE(e.submit_time, j.submit_timestamp), SECOND) AS wait_time_seconds,
    TIMESTAMP_DIFF(e.end_time, e.start_time, SECOND) AS run_time_seconds,
    TIMESTAMP_DIFF(e.end_time, COALESCE(e.submit_time, j.submit_timestamp), SECOND) AS total_time_seconds,
    
    -- Resource requests from job definition
    j.requested_cpu_cores,
    j.requested_memory_gb,
    j.requested_gpu_count,
    j.gpu_type,
    
    -- Outcome from events
    CASE 
        WHEN e.exit_status = 'COMPLETED' THEN 'SUCCESS'
        ELSE e.exit_status 
    END AS exit_status,
    e.exit_code,
    
    -- Computed consumption
    j.requested_cpu_cores * TIMESTAMP_DIFF(e.end_time, e.start_time, SECOND) AS cpu_seconds,
    j.requested_gpu_count * TIMESTAMP_DIFF(e.end_time, e.start_time, SECOND) AS gpu_seconds
    
FROM staging.jobs_cleaned j
INNER JOIN events_pivoted e USING (job_id)
WHERE e.end_time IS NOT NULL;


-- ============================================================================
-- LAYER 5: AGGREGATED TABLES (Gold Layer - Marts)
-- Pre-computed metrics for dashboards and analysis
-- ============================================================================

-- Hourly cluster utilization metrics
CREATE TABLE mart.hourly_cluster_utilization (
    hour_timestamp TIMESTAMP,
    cluster_id STRING,
    
    -- Capacity (from config)
    total_cpu_cores INT64,
    total_memory_gb FLOAT64,
    total_gpus INT64,
    
    -- Usage (from node metrics, averaged over hour)
    avg_used_cpu_cores FLOAT64,
    avg_used_memory_gb FLOAT64,
    avg_used_gpus FLOAT64,
    avg_gpu_utilization_pct FLOAT64,
    
    -- GPU utilization percentiles (from 6 samples per hour at 10-min intervals)
    p25_gpu_utilization_pct FLOAT64,
    p50_gpu_utilization_pct FLOAT64,  -- median
    p75_gpu_utilization_pct FLOAT64,
    p95_gpu_utilization_pct FLOAT64,
    p99_gpu_utilization_pct FLOAT64,
    
    -- Utilization ratios
    cpu_utilization_pct FLOAT64,
    memory_utilization_pct FLOAT64,
    gpu_allocation_pct FLOAT64,  -- GPUs allocated (may not be fully utilized)
    
    -- Job metrics
    jobs_submitted INT64,
    jobs_started INT64,
    jobs_completed INT64,
    jobs_failed INT64,
    
    -- Queue metrics
    avg_queue_depth INT64,
    avg_wait_time_seconds FLOAT64,
    p50_wait_time_seconds FLOAT64,
    p95_wait_time_seconds FLOAT64
)
PARTITION BY DATE(hour_timestamp)
CLUSTER BY cluster_id;

-- Build hourly utilization from node metrics (10-min samples → hourly with percentiles)
CREATE OR REPLACE TABLE mart.hourly_cluster_utilization AS
WITH hourly_metrics AS (
    SELECT
        TIMESTAMP_TRUNC(metric_timestamp, HOUR) AS hour_timestamp,
        cluster_id,
        -- Averages
        AVG(used_cpu_cores) AS avg_used_cpu_cores,
        AVG(used_memory_gb) AS avg_used_memory_gb,
        AVG(used_gpu_count) AS avg_used_gpus,
        AVG(gpu_utilization_pct) AS avg_gpu_utilization_pct,
        -- GPU utilization percentiles (from ~6 samples per hour per node)
        APPROX_QUANTILES(gpu_utilization_pct, 100)[OFFSET(25)] AS p25_gpu_utilization_pct,
        APPROX_QUANTILES(gpu_utilization_pct, 100)[OFFSET(50)] AS p50_gpu_utilization_pct,
        APPROX_QUANTILES(gpu_utilization_pct, 100)[OFFSET(75)] AS p75_gpu_utilization_pct,
        APPROX_QUANTILES(gpu_utilization_pct, 100)[OFFSET(95)] AS p95_gpu_utilization_pct,
        APPROX_QUANTILES(gpu_utilization_pct, 100)[OFFSET(99)] AS p99_gpu_utilization_pct,
        -- Capacity
        MAX(total_cpu_cores) AS total_cpu_cores,
        MAX(total_memory_gb) AS total_memory_gb,
        MAX(total_gpu_count) AS total_gpus
    FROM src.node_metrics
    GROUP BY 1, 2
),
hourly_jobs AS (
    SELECT
        TIMESTAMP_TRUNC(submit_time, HOUR) AS hour_timestamp,
        cluster_id,
        COUNT(*) AS jobs_submitted,
        COUNTIF(start_time IS NOT NULL) AS jobs_started,
        COUNTIF(exit_status = 'SUCCESS') AS jobs_completed,
        COUNTIF(exit_status = 'FAILED') AS jobs_failed,
        AVG(wait_time_seconds) AS avg_wait_time_seconds,
        APPROX_QUANTILES(wait_time_seconds, 100)[OFFSET(50)] AS p50_wait_time_seconds,
        APPROX_QUANTILES(wait_time_seconds, 100)[OFFSET(95)] AS p95_wait_time_seconds
    FROM fact.job_executions
    GROUP BY 1, 2
)
SELECT
    m.hour_timestamp,
    m.cluster_id,
    m.total_cpu_cores,
    m.total_memory_gb,
    m.total_gpus,
    m.avg_used_cpu_cores,
    m.avg_used_memory_gb,
    m.avg_used_gpus,
    m.avg_gpu_utilization_pct,
    -- GPU utilization percentiles
    m.p25_gpu_utilization_pct,
    m.p50_gpu_utilization_pct,
    m.p75_gpu_utilization_pct,
    m.p95_gpu_utilization_pct,
    m.p99_gpu_utilization_pct,
    -- Utilization ratios
    SAFE_DIVIDE(m.avg_used_cpu_cores, m.total_cpu_cores) * 100 AS cpu_utilization_pct,
    SAFE_DIVIDE(m.avg_used_memory_gb, m.total_memory_gb) * 100 AS memory_utilization_pct,
    SAFE_DIVIDE(m.avg_used_gpus, m.total_gpus) * 100 AS gpu_allocation_pct,
    -- Job metrics
    COALESCE(j.jobs_submitted, 0) AS jobs_submitted,
    COALESCE(j.jobs_started, 0) AS jobs_started,
    COALESCE(j.jobs_completed, 0) AS jobs_completed,
    COALESCE(j.jobs_failed, 0) AS jobs_failed,
    -- Queue metrics
    0 AS avg_queue_depth,  -- Would need separate queue snapshot data
    j.avg_wait_time_seconds,
    j.p50_wait_time_seconds,
    j.p95_wait_time_seconds
FROM hourly_metrics m
LEFT JOIN hourly_jobs j USING (hour_timestamp, cluster_id);


-- Daily utilization summary (for capacity planning)
CREATE TABLE mart.daily_cluster_summary (
    summary_date DATE,
    cluster_id STRING,
    
    -- Peak utilization
    peak_cpu_utilization_pct FLOAT64,
    peak_memory_utilization_pct FLOAT64,
    peak_gpu_allocation_pct FLOAT64,
    peak_hour INT64,  -- Hour of day with peak utilization
    
    -- Average utilization
    avg_cpu_utilization_pct FLOAT64,
    avg_memory_utilization_pct FLOAT64,
    avg_gpu_allocation_pct FLOAT64,
    
    -- Job throughput
    total_jobs_submitted INT64,
    total_jobs_completed INT64,
    total_jobs_failed INT64,
    success_rate_pct FLOAT64,
    
    -- Resource consumption
    total_cpu_hours FLOAT64,
    total_gpu_hours FLOAT64,
    
    -- Wait time SLA
    avg_wait_time_seconds FLOAT64,
    p95_wait_time_seconds FLOAT64,
    jobs_waiting_over_5min INT64,
    
    -- Cost (if available)
    estimated_cost_usd FLOAT64
)
PARTITION BY summary_date
CLUSTER BY cluster_id;


-- User-level utilization for chargeback/showback
CREATE TABLE mart.daily_user_utilization (
    summary_date DATE,
    user_id STRING,
    team STRING,
    cluster_id STRING,
    
    -- Job metrics
    jobs_submitted INT64,
    jobs_completed INT64,
    jobs_failed INT64,
    
    -- Resource consumption
    total_cpu_hours FLOAT64,
    total_gpu_hours FLOAT64,
    total_memory_gb_hours FLOAT64,
    
    -- Efficiency metrics
    avg_cpu_utilization_pct FLOAT64,  -- Actual vs requested
    avg_gpu_utilization_pct FLOAT64,
    
    -- Cost allocation
    estimated_cost_usd FLOAT64
)
PARTITION BY summary_date
CLUSTER BY user_id, cluster_id;


-- ============================================================================
-- LAYER 6: DERIVED TABLES FOR MODELING (Gold Layer - Analytics)
-- Features for forecasting and capacity planning
-- ============================================================================

-- Time series features for utilization forecasting
CREATE TABLE analytics.utilization_forecast_features AS
SELECT
    hour_timestamp,
    cluster_id,
    
    -- Target variable
    gpu_allocation_pct AS target_utilization,
    
    -- Time features
    EXTRACT(HOUR FROM hour_timestamp) AS hour_of_day,
    EXTRACT(DAYOFWEEK FROM hour_timestamp) AS day_of_week,
    EXTRACT(WEEK FROM hour_timestamp) AS week_of_year,
    EXTRACT(MONTH FROM hour_timestamp) AS month,
    
    -- Lag features (previous hours)
    LAG(gpu_allocation_pct, 1) OVER (PARTITION BY cluster_id ORDER BY hour_timestamp) AS lag_1h,
    LAG(gpu_allocation_pct, 24) OVER (PARTITION BY cluster_id ORDER BY hour_timestamp) AS lag_24h,
    LAG(gpu_allocation_pct, 168) OVER (PARTITION BY cluster_id ORDER BY hour_timestamp) AS lag_1w,
    
    -- Rolling averages
    AVG(gpu_allocation_pct) OVER (
        PARTITION BY cluster_id 
        ORDER BY hour_timestamp 
        ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
    ) AS rolling_avg_24h,
    
    AVG(gpu_allocation_pct) OVER (
        PARTITION BY cluster_id 
        ORDER BY hour_timestamp 
        ROWS BETWEEN 168 PRECEDING AND 1 PRECEDING
    ) AS rolling_avg_1w,
    
    -- Rolling max (peak detection)
    MAX(gpu_allocation_pct) OVER (
        PARTITION BY cluster_id 
        ORDER BY hour_timestamp 
        ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
    ) AS rolling_max_24h,
    
    -- Job submission rate (leading indicator)
    jobs_submitted AS hourly_job_submissions,
    LAG(jobs_submitted, 1) OVER (PARTITION BY cluster_id ORDER BY hour_timestamp) AS lag_1h_submissions
    
FROM mart.hourly_cluster_utilization;


-- Capacity planning: when will we hit capacity thresholds?
CREATE TABLE analytics.capacity_alerts AS
SELECT
    summary_date,
    cluster_id,
    peak_gpu_allocation_pct,
    avg_gpu_allocation_pct,
    
    -- Alert levels
    CASE
        WHEN peak_gpu_allocation_pct > 95 THEN 'CRITICAL'
        WHEN peak_gpu_allocation_pct > 85 THEN 'WARNING'
        WHEN peak_gpu_allocation_pct > 70 THEN 'MONITOR'
        ELSE 'OK'
    END AS capacity_status,
    
    -- Trend (week-over-week growth)
    avg_gpu_allocation_pct - LAG(avg_gpu_allocation_pct, 7) OVER (
        PARTITION BY cluster_id ORDER BY summary_date
    ) AS wow_growth_pct,
    
    -- Days until 100% at current growth rate (linear projection)
    SAFE_DIVIDE(
        100 - avg_gpu_allocation_pct,
        NULLIF(avg_gpu_allocation_pct - LAG(avg_gpu_allocation_pct, 7) OVER (
            PARTITION BY cluster_id ORDER BY summary_date
        ), 0) / 7
    ) AS days_until_full
    
FROM mart.daily_cluster_summary;


-- ============================================================================
-- ETL ORCHESTRATION: Incremental load pattern (pseudo-code)
-- ============================================================================

/*
-- Airflow/dbt pattern for incremental loads:

-- 1. Raw layer: Append-only from streaming/batch sources
INSERT INTO src.job_events
SELECT * FROM external_source.job_events_stream
WHERE ingestion_timestamp > (SELECT MAX(ingestion_timestamp) FROM src.job_events);

-- 2. Staging layer: Incremental with dedup
MERGE INTO staging.job_events_cleaned AS target
USING (
    SELECT * FROM src.job_events
    WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY ingestion_timestamp DESC) = 1
) AS source
ON target.event_id = source.event_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- 3. Fact layer: Rebuild recent partitions
DELETE FROM fact.job_executions 
WHERE DATE(submit_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY);

INSERT INTO fact.job_executions
SELECT ... FROM staging.job_events_cleaned
WHERE DATE(submit_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY);

-- 4. Mart layer: Rebuild aggregates for recent dates
-- (Similar pattern with date-bounded deletes + inserts)

*/


-- ============================================================================
-- KEY METRICS QUERIES
-- ============================================================================

-- Current cluster health dashboard
SELECT
    cluster_id,
    hour_timestamp,
    cpu_utilization_pct,
    memory_utilization_pct,
    gpu_allocation_pct,
    avg_gpu_utilization_pct,
    jobs_submitted,
    p95_wait_time_seconds,
    CASE 
        WHEN gpu_allocation_pct > 90 THEN 'HIGH'
        WHEN gpu_allocation_pct > 70 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS load_level
FROM mart.hourly_cluster_utilization
WHERE hour_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
ORDER BY cluster_id, hour_timestamp;

-- Top resource consumers (for showback)
SELECT
    user_id,
    team,
    SUM(total_gpu_hours) AS total_gpu_hours,
    SUM(estimated_cost_usd) AS total_cost,
    AVG(avg_gpu_utilization_pct) AS avg_efficiency
FROM mart.daily_user_utilization
WHERE summary_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY user_id, team
ORDER BY total_gpu_hours DESC
LIMIT 20;

-- Clusters approaching capacity
SELECT *
FROM analytics.capacity_alerts
WHERE summary_date = CURRENT_DATE() - 1
  AND capacity_status IN ('CRITICAL', 'WARNING')
ORDER BY days_until_full ASC;

-- ============================================================================
-- MULTI-NODE JOB QUERIES (using job_node_allocations)
-- ============================================================================

-- Find distributed jobs (jobs using multiple nodes)
SELECT
    j.job_id,
    j.user_id,
    j.job_type,
    COUNT(DISTINCT a.node_id) AS num_nodes,
    SUM(a.allocated_gpu_count) AS total_gpus_across_nodes,
    ARRAY_AGG(DISTINCT a.node_role) AS roles
FROM staging.jobs_cleaned j
JOIN src.job_node_allocations a USING (job_id)
GROUP BY j.job_id, j.user_id, j.job_type
HAVING COUNT(DISTINCT a.node_id) > 1
ORDER BY num_nodes DESC;

-- GPU utilization per node for a specific distributed job
SELECT
    a.job_id,
    a.node_id,
    a.node_role,
    a.node_rank,
    a.allocated_gpu_count,
    a.gpu_device_ids,
    AVG(m.gpu_utilization_pct) AS avg_gpu_util_on_node
FROM src.job_node_allocations a
JOIN src.node_metrics m 
    ON a.node_id = m.node_id
    AND m.metric_timestamp BETWEEN a.allocation_start AND COALESCE(a.allocation_end, CURRENT_TIMESTAMP())
WHERE a.job_id = 'job_123'  -- specific job
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY a.node_rank;

-- Find jobs currently running on a specific node
SELECT
    a.job_id,
    j.user_id,
    j.job_type,
    a.allocation_start,
    a.allocated_gpu_count,
    a.node_role
FROM src.job_node_allocations a
JOIN staging.jobs_cleaned j USING (job_id)
WHERE a.node_id = 'node_abc'
  AND a.allocation_end IS NULL  -- still running
ORDER BY a.allocation_start;
