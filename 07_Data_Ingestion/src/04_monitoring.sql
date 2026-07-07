-- ==============================================================================
-- 04_monitoring.sql
-- Description: Operational Views for Airflow SLA Sensors
-- Phase: 07 - Data Ingestion
-- ==============================================================================

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_PIPELINE;

-- 1. View: Snowpipe Ingestion Latency
-- Measures the time between AWS S3 file creation and Snowflake insertion.
CREATE OR REPLACE SECURE VIEW VW_SNOWPIPE_LATENCY AS
SELECT 
    pipe_name,
    file_name,
    file_size,
    row_count,
    last_load_time,
    DATEDIFF('second', file_last_modified, last_load_time) AS ingestion_latency_seconds,
    status,
    error_count
FROM TABLE(DB_PROD_RAW.INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME=>'DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS', 
    START_TIME=> DATEADD(days, -7, CURRENT_TIMESTAMP())
));

-- 2. View: Quarantine Volumes (DLQ Monitoring)
CREATE OR REPLACE SECURE VIEW VW_DLQ_METRICS AS
SELECT 
    Source_System,
    DATE_TRUNC('hour', Quarantine_Time) as Quarantine_Hour,
    COUNT(*) as Error_Volume,
    Validation_Error
FROM DB_PROD_RAW.SC_BRONZE_QUARANTINE.TB_DLQ_PAYLOADS
GROUP BY 1, 2, 4
ORDER BY 2 DESC;
