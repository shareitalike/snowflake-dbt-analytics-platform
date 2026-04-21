/* ==============================================================================
 * FILE: 02_stream_monitoring_views.sql
 * PHASE: 08 - CDC Framework (Module 2)
 * 
 * EXPLANATION: Creates secure views for monitoring CDC stream health, specifically identifying streams at risk of becoming stale and checking for active data volumes.
 * DESIGN DECISIONS: Uses INFORMATION_SCHEMA.TABLES to monitor the stale_after timestamp, calculating the hours until a stream becomes unreadable (usually 14 days). Employs SYSTEM$STREAM_HAS_DATA for lightweight offset checks.
 * WHY: Monitoring stream staleness prevents silent data loss due to pipeline pauses or failures exceeding the retention period. SYSTEM$STREAM_HAS_DATA is used over COUNT(*) because it checks metadata instantly without consuming the stream offset or requiring compute warehouse spin-up.
 * ============================================================================== */

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_PIPELINE;

-- 1. View: CDC Stream Stale Risk Monitor
-- Identifies streams that are approaching the 14-day data retention limit, 
-- at which point the stream will become stale and unreadable.
CREATE OR REPLACE SECURE VIEW VW_CDC_STREAM_HEALTH AS
SELECT 
    table_catalog AS database_name,
    table_schema AS schema_name,
    table_name AS stream_name,
    created AS stream_created_at,
    stale AS is_stale,
    stale_after AS stale_after_timestamp,
    DATEDIFF('hour', CURRENT_TIMESTAMP(), stale_after) AS hours_until_stale
FROM DB_PROD_RAW.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'STREAM'
  AND is_stale = 'NO'
ORDER BY hours_until_stale ASC;

-- 2. View: CDC Volume Monitor (Current Offset)
-- Note: SYSTEM$STREAM_HAS_DATA is highly efficient as it checks metadata.
-- For actual row counts without consuming the stream, we can union them. 
-- (This view is a lightweight check for active streams)
CREATE OR REPLACE SECURE VIEW VW_CDC_ACTIVE_STREAMS AS
SELECT 'DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS' AS Stream_Name, SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS') AS Has_Data
UNION ALL
SELECT 'DB_PROD_RAW.SC_BRONZE_STRIPE.STR_STRIPE_PAYMENTS', SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_STRIPE.STR_STRIPE_PAYMENTS')
UNION ALL
SELECT 'DB_PROD_RAW.SC_BRONZE_POS.STR_POS_INVENTORY', SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_POS.STR_POS_INVENTORY');
