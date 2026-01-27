# SQL Cheatsheet (BigQuery)

Common SQL patterns for data analysis.

## 1. Common Table Expressions (CTEs) with WITH

CTEs create temporary named result sets that can be referenced in the main query.

```sql
WITH protocol_requests AS (
    SELECT ... FROM table1
),
test_request_ids AS (
    SELECT DISTINCT test_request_id FROM protocol_requests
),
executions AS (
    SELECT ... FROM table2
)
SELECT * 
FROM protocol_requests
LEFT JOIN executions ON ...
```

> **Key pattern:** Chain multiple CTEs with commas, then use them in the final SELECT.

## 2. JOIN Types

**LEFT JOIN** - Keep all rows from left table, match from right (nulls if no match):

```sql
SELECT protocol_requests.*, executions.*
FROM protocol_requests
LEFT JOIN executions
    ON executions.test_request_id = protocol_requests.test_request_id
```

**INNER JOIN** - Only keep rows that match in both tables:

```sql
FROM decorated_protocol_trg_test_requests trgtr
INNER JOIN decorated_protocol_test_request_groups trg
    ON trg.test_request_group_id = trgtr.test_request_group_id
```

## 3. UNION ALL

Combine results from multiple queries (must have same columns):

```sql
SELECT col1, col2, 'protocol' AS protocol_version
FROM table1
WHERE ...

UNION ALL

SELECT col1, col2, 'trg_protocol' AS protocol_version
FROM table2
WHERE ...
```

## 4. Window Functions with ROW_NUMBER()

Assign row numbers within partitions for "get latest" queries:

```sql
WITH ranked_runs AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY testing_protocol_execution_id, analyzer_path
            ORDER BY created_at DESC
        ) as rn
    FROM protocol_analysis
)
SELECT * EXCEPT(rn)
FROM ranked_runs
WHERE rn = 1  -- Get only the latest row per partition
```

## 5. Aggregate Functions with GROUP BY

```sql
SELECT
    testing_protocol_execution_id,
    COUNT(DISTINCT test_request_id) AS total_requests,
    SUM(total_test_executions) AS total_executions,
    MIN(protocol_created_at) AS created_at,
    MAX(protocol_completed_at) AS ended_at,
    ANY_VALUE(trigger_metadata) AS trigger_metadata,  -- Pick any value from group
    STRING_AGG(DISTINCT status ORDER BY status) AS all_statuses  -- Concatenate strings
FROM joined_requests
GROUP BY testing_protocol_execution_id
```

## 6. CASE WHEN Expressions

Conditional logic in SQL:

```sql
SELECT
    CASE
        WHEN JSON_QUERY(definition, '$.metadata.tags.generator') IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS has_generator_tag,
    
    CASE 
        WHEN NOT is_feature_test_request THEN git_branch 
        ELSE NULL 
    END AS base_branch
```

## 7. JSON Functions (BigQuery-specific)

```sql
-- Extract scalar value from JSON
JSON_EXTRACT_SCALAR(trg.requestor, '$.user_email') AS requested_by

-- Extract JSON object/array
JSON_EXTRACT(r.trigger_metadata, '$.coreProtocolCliParams')

-- JSON_VALUE is similar to JSON_EXTRACT_SCALAR
JSON_VALUE(dsd.definition, '$.metadata.tags.scenariokit_project')

-- Check if JSON path exists
JSON_QUERY(dsd.definition, '$.metadata.tags.generator') IS NOT NULL

-- Convert to JSON string
TO_JSON_STRING(extracted)
```

## 8. UNNEST for Arrays

Flatten array columns into rows:

```sql
-- Basic UNNEST in FROM clause
SELECT scores.name as score_name
FROM `table` exe, UNNEST(exe.execution.scores) AS scores

-- UNNEST with alias for complex queries
SELECT
    fr.testing_protocol_execution_id,
    score.name AS score_name,
    score.score_json
FROM filtered_runs AS fr,
UNNEST(fr.protocol_scores) AS score
```

## 9. EXISTS Subquery

Check if matching rows exist:

```sql
WHERE EXISTS (
    SELECT 1
    FROM UNNEST(pa.protocol_scores) AS ps
    WHERE ps.name = 'top_mover'
    AND JSON_VALUE(ps.score_json, '$.is_top_mover') = 'true'
)
```

## 10. COALESCE, IFNULL, and NULLIF

Handle NULL values:

```sql
-- COALESCE returns first non-null value
COALESCE(
    SAFE_CAST(ds.evaluation_start_time AS NUMERIC),
    SAFE_CAST(JSON_VALUE(dsd.definition, '$.config.evaluation_start_time') AS NUMERIC)
) AS evaluation_start_time

-- IFNULL provides default when null
IFNULL(JSON_EXTRACT(...), '{}') AS trigger_metadata

-- NULLIF returns NULL if both arguments are equal (useful to avoid division by zero)
SELECT total / NULLIF(AVG(diff), 0) AS rate  -- Returns NULL instead of error if AVG(diff) = 0

-- Common pattern: safe division
SELECT 
    numerator / NULLIF(denominator, 0) AS safe_ratio,
    COALESCE(numerator / NULLIF(denominator, 0), 0) AS safe_ratio_with_default
```

## 11. SELECT * EXCEPT

Select all columns except specified ones:

```sql
SELECT
    protocol_requests.*,
    executions.* EXCEPT(test_request_id)  -- Avoid duplicate column
FROM protocol_requests
LEFT JOIN executions ON ...
```

## 12. Parameterized Queries

Use `@param_name` for safe parameter injection:

```sql
WHERE r.testing_protocol_execution_id IN UNNEST(@execution_ids)
AND created_at >= @start_ts
AND created_at <= @end_ts
```

## 13. CAST and SAFE_CAST

Type conversions:

```sql
-- CAST throws error on failure
CAST(JSON_EXTRACT_SCALAR(score.score_json, '$.burndown_solved_base') AS INT64)

-- SAFE_CAST returns NULL on failure
SAFE_CAST(JSON_VALUE(dsd.definition, '$.metadata.tags.application') AS STRING)
```

## 14. Timestamp Functions

```sql
-- Difference between timestamps
TIMESTAMP_DIFF(MAX(completed_at), MIN(created_at), SECOND) / 3600 AS duration_h

-- Convert to milliseconds
UNIX_MILLIS(events.start_time)

-- Arithmetic with timestamps
(UNIX_MICROS(events.end_time) - UNIX_MICROS(events.start_time)) / 1e6 AS duration_seconds
```

## 15. Conditional Aggregation Pattern

Count different categories in one pass:

```sql
SELECT
    COUNT(DISTINCT(CASE WHEN NOT is_feature THEN test_request_id ELSE NULL END)) AS base_requests,
    COUNT(DISTINCT(CASE WHEN is_feature THEN test_request_id ELSE NULL END)) AS feature_requests
```

## 16. Subquery in WHERE Clause

```sql
WHERE test_request_id IN (SELECT test_request_id FROM test_request_ids)
```

## 17. CONCAT for String Building

```sql
CONCAT(
    tr.webviz_url,
    "&start=",
    CAST(UNIX_MILLIS(events.start_time) - 1000 AS STRING),
    "&end=",
    CAST(UNIX_MILLIS(events.end_time) + 1000 AS STRING)
) AS event_webviz_url
```

## 18. IF Expression

```sql
IF(COUNT(completed_at) < COUNT(*), NULL, MAX(completed_at)) AS last_completed
```

## 19. Window Frame: ROWS vs RANGE

Use `ROWS BETWEEN` (physical window) instead of the default `RANGE` (logical window) to handle simultaneous events correctly and avoid BigQuery memory issues.

```sql
-- Bad: RANGE (default) can cause memory crashes with duplicate timestamps
SUM(value) OVER (ORDER BY timestamp)  -- Implicitly uses RANGE

-- Good: ROWS handles simultaneous events correctly
SUM(value) OVER (
    ORDER BY timestamp 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)

-- Running total with explicit window frame
SELECT
    timestamp,
    value,
    SUM(value) OVER (
        PARTITION BY user_id
        ORDER BY timestamp
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM events
```

> **Gotcha:** `RANGE` groups rows with identical ORDER BY values together, which can cause unexpected results and memory issues. `ROWS` processes each row individually.

## 20. Approximate Quantiles (P95, P99)

Use `APPROX_QUANTILES` for tail risk metrics at scale. Standard `PERCENTILE_CONT` is too slow for petabyte-scale logs.

```sql
-- P95 wait time (fast approximation)
SELECT
    DATE(submission_time) AS usage_date,
    APPROX_QUANTILES(wait_seconds, 100)[OFFSET(95)] AS p95_wait,
    APPROX_QUANTILES(wait_seconds, 100)[OFFSET(99)] AS p99_wait,
    APPROX_QUANTILES(wait_seconds, 100)[OFFSET(50)] AS median_wait
FROM job_logs
GROUP BY 1

-- Multiple percentiles in one pass
SELECT
    APPROX_QUANTILES(duration, 100)[OFFSET(50)] AS p50,
    APPROX_QUANTILES(duration, 100)[OFFSET(90)] AS p90,
    APPROX_QUANTILES(duration, 100)[OFFSET(95)] AS p95,
    APPROX_QUANTILES(duration, 100)[OFFSET(99)] AS p99
FROM execution_logs
```

> **Why approximation?** Exact percentiles require sorting all data; approximations use sketches and are accurate enough for capacity planning and SLA monitoring.

## 21. Time Spine for Gap Analysis

Join logs to a generated time series to find "quiet hours" where utilization is low.

```sql
-- Generate hourly time spine
WITH time_spine AS (
    SELECT hour
    FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY(
            TIMESTAMP('2025-01-01'),
            TIMESTAMP('2025-01-31'),
            INTERVAL 1 HOUR
        )
    ) AS hour
),
hourly_usage AS (
    SELECT
        TIMESTAMP_TRUNC(start_time, HOUR) AS hour,
        COUNT(*) AS jobs_running
    FROM job_logs
    GROUP BY 1
)
SELECT
    ts.hour,
    COALESCE(hu.jobs_running, 0) AS jobs_running,
    CASE 
        WHEN COALESCE(hu.jobs_running, 0) < 50 THEN 'quiet'
        WHEN COALESCE(hu.jobs_running, 0) < 80 THEN 'normal'
        ELSE 'busy'
    END AS utilization_band
FROM time_spine ts
LEFT JOIN hourly_usage hu ON ts.hour = hu.hour
ORDER BY ts.hour
```

> **Use case:** Find hours where utilization is <50% to identify capacity for batch jobs or maintenance windows.

---

## Summary

| Pattern | Use Case |
|---------|----------|
| `WITH ... AS` | Break complex queries into readable parts |
| `LEFT JOIN` | Keep all left rows, match optionally |
| `INNER JOIN` | Only matching rows |
| `UNION ALL` | Combine multiple result sets |
| `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` | Rank/filter within groups |
| `GROUP BY` + aggregates | Summarize data |
| `CASE WHEN` | Conditional logic |
| `JSON_EXTRACT_SCALAR()` | Get JSON values |
| `UNNEST()` | Flatten arrays |
| `EXISTS (SELECT 1 ...)` | Check existence |
| `COALESCE()` / `IFNULL()` / `NULLIF()` | Handle NULLs, avoid division by zero |
| `* EXCEPT(col)` | Exclude specific columns |
| `@param` | Parameterized queries |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | Safe window frames for running totals |
| `APPROX_QUANTILES(..., 100)[OFFSET(95)]` | Fast P95/P99 at scale |
| `GENERATE_TIMESTAMP_ARRAY` | Time spine for gap analysis |
