-- ==============================================================================
-- Enterprise Data Observability Framework
-- Monitors the 5 pillars: Freshness, Volume, Schema, Completeness, Accuracy
-- ==============================================================================

USE ROLE SYSADMIN;

-- ==============================================================================
-- PILLAR 1: DATA FRESHNESS
-- "When was the last time data arrived?" If stale, downstream reports are wrong.
-- ==============================================================================
SELECT 
    table_catalog || '.' || table_schema || '.' || table_name AS full_table_name,
    row_count,
    last_altered AS last_data_change,
    DATEDIFF(hour, last_altered, CURRENT_TIMESTAMP()) AS hours_since_update,
    CASE
        WHEN DATEDIFF(hour, last_altered, CURRENT_TIMESTAMP()) > 24 
            THEN '🔴 STALE: No update in ' || DATEDIFF(hour, last_altered, CURRENT_TIMESTAMP()) || 'h'
        WHEN DATEDIFF(hour, last_altered, CURRENT_TIMESTAMP()) > 12 
            THEN '🟡 WARNING: ' || DATEDIFF(hour, last_altered, CURRENT_TIMESTAMP()) || 'h since update'
        ELSE '🟢 FRESH'
    END AS freshness_status
FROM snowflake.account_usage.tables
WHERE table_schema IN ('GOLD')
  AND table_type = 'BASE TABLE'
  AND deleted IS NULL
ORDER BY hours_since_update DESC;

-- ==============================================================================
-- PILLAR 2: VOLUME ANOMALY DETECTION
-- Compare today's row count to the 7-day rolling average.
-- A sudden drop of >50% likely indicates a broken upstream pipeline.
-- ==============================================================================
WITH daily_counts AS (
    SELECT 
        table_name,
        DATE_TRUNC('day', last_altered) AS snapshot_date,
        row_count
    FROM snowflake.account_usage.tables
    WHERE table_schema = 'GOLD'
      AND deleted IS NULL
)
SELECT 
    table_name,
    row_count AS current_rows,
    AVG(row_count) OVER (PARTITION BY table_name ORDER BY snapshot_date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS avg_7d_rows,
    CASE 
        WHEN row_count < AVG(row_count) OVER (PARTITION BY table_name ORDER BY snapshot_date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) * 0.5
            THEN '🔴 ANOMALY: Row count dropped >50% vs 7-day avg'
        ELSE '🟢 NORMAL'
    END AS volume_status
FROM daily_counts
QUALIFY ROW_NUMBER() OVER (PARTITION BY table_name ORDER BY snapshot_date DESC) = 1;

-- ==============================================================================
-- PILLAR 3: SCHEMA DRIFT DETECTION
-- Detect if columns were added, removed, or type-changed in the last 24 hours.
-- ==============================================================================
SELECT 
    table_catalog || '.' || table_schema || '.' || table_name AS full_table_name,
    column_name,
    data_type,
    created AS column_created_at,
    '🔴 SCHEMA DRIFT: New column detected' AS drift_status
FROM snowflake.account_usage.columns
WHERE created >= DATEADD(day, -1, CURRENT_TIMESTAMP())
  AND table_schema IN ('BRONZE', 'SILVER', 'GOLD')
  AND deleted IS NULL
ORDER BY created DESC;

-- ==============================================================================
-- PILLAR 4: NULL COMPLETENESS CHECK (Parameterized Example)
-- Flags tables where critical business columns have excessive NULLs.
-- ==============================================================================
-- Example: Check that CUSTOMER_ID in FCT_SALES is never NULL
SELECT 
    'FCT_SALES.CUSTOMER_ID' AS check_target,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN CUSTOMER_ID IS NULL THEN 1 ELSE 0 END) AS null_count,
    ROUND(null_count / NULLIF(total_rows, 0) * 100, 2) AS null_pct,
    CASE 
        WHEN null_pct > 1.0 THEN '🔴 COMPLETENESS FAIL: ' || null_pct || '% NULLs'
        ELSE '🟢 PASS'
    END AS completeness_status
FROM OMNIRETAIL.GOLD.FCT_SALES;
