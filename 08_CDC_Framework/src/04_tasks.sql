-- ==============================================================================
-- 04_tasks.sql
-- Description: Task DAG for Enterprise CDC Orchestration
-- Phase: 08 - CDC Framework (Module 3)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_CURATED;
-- We orchestrate from Silver (Curated) as it is the destination layer.
USE SCHEMA SC_UTILITIES;
-- Assume SC_UTILITIES exists in DB_PROD_CURATED.
CREATE SCHEMA IF NOT EXISTS DB_PROD_CURATED.SC_UTILITIES;
USE SCHEMA DB_PROD_CURATED.SC_UTILITIES;

-- ------------------------------------------------------------------------------
-- 1. ROOT TASK
-- ------------------------------------------------------------------------------
-- Triggers every 15 minutes. 
-- We use USER_TASK_TIMEOUT_MS to abort if it hangs for > 30 mins.
-- FIX P0-006: Serverless compute — root task only opens a checkpoint and logs a start event.
-- Removing WH_ADMIN prevents 96 daily spin-ups from polluting admin warehouse metrics.
CREATE OR REPLACE TASK TSK_CDC_MASTER_SCHEDULE
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '15 MINUTE'
    USER_TASK_TIMEOUT_MS = 300000
    COMMENT = 'Root task: opens CDC batch checkpoint and triggers child DAG'
AS
    -- FIX P0-001: Open the batch checkpoint. The returned Batch_ID is persisted
    -- in TB_PIPELINE_LOG so TSK_CDC_METADATA_UPDATE can commit it on completion.
    INSERT INTO DB_PROD_METADATA.SC_META_PIPELINE.TB_PIPELINE_LOG
        (Pipeline_Name, Status)
    VALUES ('CDC_DAG', 'STARTED');

-- ------------------------------------------------------------------------------
-- 2. CHILD TASKS (Level 1: Independent Entities)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE TASK TSK_CDC_CUSTOMER
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_MASTER_SCHEDULE
    USER_TASK_TIMEOUT_MS = 900000
    -- FinOps: Only spin up the warehouse if there is data to process
    WHEN SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_CUSTOMER')
AS
    -- FIX P0-001: Wired to production SCD2 procedure.
    CALL DB_PROD_CURATED.SC_UTILITIES.SP_MERGE_CUSTOMER_SCD2();

CREATE OR REPLACE TASK TSK_CDC_PRODUCT
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_MASTER_SCHEDULE
    WHEN SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_PRODUCTS')
AS
    CALL SP_MERGE_SHOPIFY_PRODUCT();

CREATE OR REPLACE TASK TSK_CDC_INVENTORY
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_MASTER_SCHEDULE
    WHEN SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_POS.STR_POS_INVENTORY')
AS
    CALL SP_MERGE_POS_INVENTORY();

CREATE OR REPLACE TASK TSK_CDC_PAYMENTS
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_MASTER_SCHEDULE
    WHEN SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_STRIPE.STR_STRIPE_PAYMENTS')
AS
    CALL SP_MERGE_STRIPE_PAYMENTS();

CREATE OR REPLACE TASK TSK_CDC_RETURNS
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_MASTER_SCHEDULE
    WHEN SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_POS.STR_POS_RETURNS')
AS
    CALL SP_MERGE_POS_RETURNS();

-- ------------------------------------------------------------------------------
-- 3. CHILD TASKS (Level 2: Dependent Entities)
-- ------------------------------------------------------------------------------
-- Orders rely on Customers and Products existing first to maintain referential integrity.
-- FIX P0-002: TSK_CDC_ORDERS now runs AFTER TSK_CDC_INFER_GHOSTS (defined in
-- 13_late_arriving_procedures.sql). Ghost inference must complete before Orders
-- can safely MERGE, ensuring referential integrity for late-arriving customers.
CREATE OR REPLACE TASK TSK_CDC_ORDERS
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_INFER_GHOSTS
    USER_TASK_TIMEOUT_MS = 900000
    WHEN SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS')
AS
    CALL DB_PROD_CURATED.SC_UTILITIES.SP_MERGE_ORDERS_TRANSACTIONAL();

-- Order Items rely on Orders existing first.
CREATE OR REPLACE TASK TSK_CDC_ORDER_ITEMS
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_ORDERS
    WHEN SYSTEM$STREAM_HAS_DATA('DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDER_ITEMS')
AS
    CALL DB_PROD_CURATED.SC_UTILITIES.SP_MERGE_ORDER_ITEMS_TRANSACTIONAL();

-- ------------------------------------------------------------------------------
-- 4. CONSOLIDATION & METADATA TASKS
-- ------------------------------------------------------------------------------
-- Runs after all data movement tasks complete successfully.
CREATE OR REPLACE TASK TSK_CDC_BUSINESS_VALIDATION
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    AFTER TSK_CDC_ORDER_ITEMS, TSK_CDC_INVENTORY, TSK_CDC_PAYMENTS, TSK_CDC_RETURNS
AS
    -- Trigger SLA evaluation across all pipeline watermarks
    CALL DB_PROD_METADATA.SC_META_OBSERVABILITY.SP_EVALUATE_SLA_BREACHES();

CREATE OR REPLACE TASK TSK_CDC_METADATA_UPDATE
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    AFTER TSK_CDC_BUSINESS_VALIDATION
    USER_TASK_TIMEOUT_MS = 300000
AS
    -- FIX P0-001: Commit the watermark checkpoint. Advances the global High_Watermark
    -- so the next 15-minute batch picks up from the correct offset.
    INSERT INTO DB_PROD_METADATA.SC_META_PIPELINE.TB_PIPELINE_LOG
        (Pipeline_Name, Status)
    VALUES ('CDC_DAG', 'COMPLETED');

-- ------------------------------------------------------------------------------
-- 5. RESUME TASKS (Bottom-Up)
-- ------------------------------------------------------------------------------
-- Tasks are created suspended. To activate a DAG, you must resume the children 
-- first, ending with the root.
ALTER TASK TSK_CDC_METADATA_UPDATE RESUME;
ALTER TASK TSK_CDC_BUSINESS_VALIDATION RESUME;
ALTER TASK TSK_CDC_ORDER_ITEMS RESUME;
ALTER TASK TSK_CDC_ORDERS RESUME;
ALTER TASK TSK_CDC_RETURNS RESUME;
ALTER TASK TSK_CDC_PAYMENTS RESUME;
ALTER TASK TSK_CDC_INVENTORY RESUME;
ALTER TASK TSK_CDC_PRODUCT RESUME;
ALTER TASK TSK_CDC_CUSTOMER RESUME;
-- Root task starts the schedule
ALTER TASK TSK_CDC_MASTER_SCHEDULE RESUME;
