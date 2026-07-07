-- ==============================================================================
-- Enterprise FinOps Monitoring Dashboard Queries
-- Run these against SNOWFLAKE.ACCOUNT_USAGE to track spend and identify waste.
-- ==============================================================================

USE ROLE ACCOUNTADMIN;

-- 1. Top 20 Most Expensive Queries (Last 30 Days)
-- This is the single most impactful FinOps query. Find the offenders and optimize them.
SELECT 
    query_id,
    user_name,
    role_name,
    warehouse_name,
    ROUND(total_elapsed_time / 1000, 2) AS elapsed_seconds,
    ROUND(credits_used_cloud_services, 4) AS cloud_credits,
    rows_produced,
    bytes_scanned,
    partitions_scanned,
    partitions_total,
    ROUND(partitions_scanned / NULLIF(partitions_total, 0) * 100, 1) AS partition_scan_pct,
    query_text
FROM snowflake.account_usage.query_history
WHERE 
    start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    AND total_elapsed_time > 60000 -- Only queries > 60 seconds
ORDER BY total_elapsed_time DESC
LIMIT 20;

-- 2. Credit Consumption by Warehouse (Daily Trend)
-- Shows which warehouse is burning the most credits and when.
SELECT 
    warehouse_name,
    DATE_TRUNC('day', start_time) AS usage_date,
    ROUND(SUM(credits_used), 2) AS total_credits
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2
ORDER BY usage_date DESC, total_credits DESC;

-- 3. Credit Consumption by Domain / Team
-- Uses the Warehouse naming convention (e.g., PROD_DBT_WH -> "DBT" team) to assign cost.
SELECT 
    SPLIT_PART(warehouse_name, '_', 2) AS team_or_domain,
    ROUND(SUM(credits_used), 2) AS monthly_credits,
    ROUND(SUM(credits_used) * 3.00, 2) AS estimated_cost_usd -- Assuming $3/credit
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD(month, -1, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY monthly_credits DESC;

-- 4. Warehouse Utilization (Idle vs Active Time)
-- Identifies warehouses that are running but not executing queries (waste).
SELECT 
    warehouse_name,
    ROUND(AVG(avg_running), 2) AS avg_queries_running,
    ROUND(AVG(avg_queued_load), 2) AS avg_queries_queued,
    COUNT(*) AS measurement_count
FROM snowflake.account_usage.warehouse_load_history
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY avg_queries_running ASC; -- Lowest utilization at top = potential waste

-- 5. Storage Cost Breakdown (Active, Time Travel, Fail-safe)
SELECT 
    table_catalog AS database_name,
    ROUND(SUM(active_bytes) / POWER(1024, 4), 4) AS active_tb,
    ROUND(SUM(time_travel_bytes) / POWER(1024, 4), 4) AS time_travel_tb,
    ROUND(SUM(failsafe_bytes) / POWER(1024, 4), 4) AS failsafe_tb,
    ROUND((SUM(active_bytes) + SUM(time_travel_bytes) + SUM(failsafe_bytes)) / POWER(1024, 4), 4) AS total_tb
FROM snowflake.account_usage.table_storage_metrics
GROUP BY 1
ORDER BY total_tb DESC;
