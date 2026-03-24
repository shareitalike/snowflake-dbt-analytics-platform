/* ==============================================================================
 * FILE: 01_streams_and_tasks.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Stubs out the basic orchestration tasks and CDC streams for the Bronze layer.
 * DESIGN DECISIONS: Demonstrates creating an append-only stream and a scheduled task that executes a stored procedure only when the stream has data (SYSTEM$STREAM_HAS_DATA).
 * WHY: This serves as an architectural template for event-driven processing, optimizing compute costs by ensuring the warehouse only wakes up if new data has arrived in the stream.
 * ============================================================================== */

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_RAW;
USE SCHEMA SC_BRONZE_SHOPIFY;

-- Note: The physical bronze tables will be instantiated via Snowpipe.
-- We stub the streams here for the CDC architecture.

-- 1. Stream on Bronze Orders
-- CREATE STREAM IF NOT EXISTS STR_SHOPIFY_ORDERS 
-- ON TABLE TB_RAW_SHOPIFY_ORDERS
-- APPEND_ONLY = TRUE;

-- 2. Orchestration Task
-- CREATE TASK IF NOT EXISTS TSK_PROCESS_SHOPIFY_ORDERS
-- WAREHOUSE = WH_TRANSFORM
-- SCHEDULE = '15 MINUTE'
-- WHEN SYSTEM$STREAM_HAS_DATA('STR_SHOPIFY_ORDERS')
-- AS
-- CALL DB_PROD_CURATED.SC_UTILITIES.SP_FLATTEN_SHOPIFY_JSON();

-- (Tasks are suspended by default, require ALTER TASK ... RESUME)
