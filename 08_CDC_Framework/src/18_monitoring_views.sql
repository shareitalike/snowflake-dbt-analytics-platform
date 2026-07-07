-- ==============================================================================
-- 18_monitoring_views.sql
-- Description: Operational Views traversing Snowflake Information Schema
-- Phase: 08 - CDC Framework (Module 8)
-- ==============================================================================

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_OBSERVABILITY;

-- ------------------------------------------------------------------------------
-- 1. PIPELINE SLA MONITOR (Data Freshness)
-- ------------------------------------------------------------------------------
-- Combines the Watermark table with current timestamp to measure exact CDC latency
CREATE OR REPLACE SECURE VIEW VW_PIPELINE_FRESHNESS_SLA AS
SELECT 
    w.Pipeline_ID,
    p.Target_Table_Name,
    w.High_Watermark AS Last_Processed_Timestamp,
    DATEDIFF('minute', w.High_Watermark, CURRENT_TIMESTAMP()) AS Data_Latency_Minutes,
    CASE 
        WHEN DATEDIFF('minute', w.High_Watermark, CURRENT_TIMESTAMP()) > 60 THEN 'BREACH'
        WHEN DATEDIFF('minute', w.High_Watermark, CURRENT_TIMESTAMP()) > 30 THEN 'WARNING'
        ELSE 'HEALTHY'
    END AS SLA_Status
FROM DB_PROD_METADATA.SC_META_CONTROL.TB_WATERMARK w
JOIN DB_PROD_METADATA.SC_META_CONTROL.TB_PIPELINE_REGISTER p 
  ON w.Pipeline_ID = p.Pipeline_ID;

-- ------------------------------------------------------------------------------
-- 2. WAREHOUSE CREDIT USAGE (Cost Attribution)
-- ------------------------------------------------------------------------------
-- Tracks credit consumption specifically for the WH_TRANSFORM warehouse
CREATE OR REPLACE SECURE VIEW VW_WAREHOUSE_CREDIT_USAGE AS
SELECT 
    WAREHOUSE_NAME,
    START_TIME::DATE AS USAGE_DATE,
    SUM(CREDITS_USED) AS TOTAL_CREDITS,
    SUM(CREDITS_USED_COMPUTE) AS COMPUTE_CREDITS,
    SUM(CREDITS_USED_CLOUD_SERVICES) AS CLOUD_SERVICES_CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'WH_TRANSFORM'
  AND START_TIME >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME, USAGE_DATE
ORDER BY USAGE_DATE DESC;

-- ------------------------------------------------------------------------------
-- 3. TASK FAILURE MONITOR
-- ------------------------------------------------------------------------------
-- Scans TASK_HISTORY for recent failures
CREATE OR REPLACE SECURE VIEW VW_RECENT_TASK_FAILURES AS
SELECT 
    NAME AS TASK_NAME,
    STATE,
    ERROR_MESSAGE,
    SCHEDULED_TIME,
    COMPLETED_TIME
FROM TABLE(DB_PROD_CURATED.INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -24, CURRENT_TIMESTAMP())
))
WHERE STATE = 'FAILED'
ORDER BY SCHEDULED_TIME DESC;

-- ------------------------------------------------------------------------------
-- 4. SNOWPIPE INGESTION HISTORY
-- ------------------------------------------------------------------------------
-- Monitors the Bronze layer auto-ingest latency
CREATE OR REPLACE SECURE VIEW VW_SNOWPIPE_LATENCY AS
SELECT 
    PIPE_NAME,
    SUM(FILE_COUNT) AS FILES_PROCESSED,
    SUM(ROW_COUNT) AS ROWS_INSERTED,
    AVG(DATEDIFF('second', LAST_LOAD_TIME, CURRENT_TIMESTAMP())) AS AVG_LATENCY_SECONDS
FROM TABLE(DB_PROD_RAW.INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
    DATE_RANGE_START=>DATEADD('day', -1, CURRENT_TIMESTAMP())
))
GROUP BY PIPE_NAME;
