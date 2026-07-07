-- ==============================================================================
-- 02_dynamic_tables.sql
-- Description: Sub-minute latency dynamic tables
-- ==============================================================================

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
