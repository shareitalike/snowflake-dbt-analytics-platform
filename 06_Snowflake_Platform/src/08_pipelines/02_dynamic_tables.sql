/* ==============================================================================
 * FILE: 02_dynamic_tables.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Provides an example configuration for Snowflake Dynamic Tables intended for sub-minute latency use cases.
 * DESIGN DECISIONS: Specifies TARGET_LAG = '1 minute' and points to the WH_TRANSFORM warehouse, aggregating raw POS inventory ticks into current stock levels.
 * WHY: Dynamic Tables are used specifically for real-time operational dashboards (like inventory alerts) that cannot wait for the standard hourly dbt batch run, offering declarative data pipeline definitions.
 * ============================================================================== */

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_ANALYTICS;
USE SCHEMA SC_GOLD_CORE;

-- Dynamic Tables are used sparingly per our ADR, specifically for sub-minute 
-- real-time inventory dashboards that bypass the hourly dbt batch.

-- Example Dynamic Table (Commented out until Base tables are populated via Snowpipe)
-- CREATE OR REPLACE DYNAMIC TABLE DT_REALTIME_INVENTORY_ALERTS
-- TARGET_LAG = '1 minute'
-- WAREHOUSE = WH_TRANSFORM
-- AS
-- SELECT 
--     Store_SK,
--     Product_SK,
--     SUM(Quantity) as Current_Stock
-- FROM DB_PROD_RAW.SC_BRONZE_POS.TB_RAW_INVENTORY_TICK
-- GROUP BY Store_SK, Product_SK
-- HAVING SUM(Quantity) < 5;
