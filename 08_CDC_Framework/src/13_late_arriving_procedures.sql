-- ==============================================================================
-- 13_late_arriving_procedures.sql
-- Description: Inferred Member (Ghost Dimension) logic for Late Arriving Data
-- Phase: 08 - CDC Framework (Module 6)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_CURATED;
USE SCHEMA SC_UTILITIES;

-- ------------------------------------------------------------------------------
-- 1. GHOST DIMENSION PROCEDURE (Customer)
-- ------------------------------------------------------------------------------
-- This procedure is called IMMEDIATELY BEFORE the Transactional Orders MERGE.
-- It scans the incoming Orders stream. If any Customer_ID does not exist in the 
-- Customer Dimension, it proactively creates a "Ghost" record.

CREATE OR REPLACE PROCEDURE SP_INFER_LATE_CUSTOMERS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    -- FIX P2-007: Replaced NOT IN (SELECT ... FROM large_table) with a LEFT JOIN anti-join.
    -- At millions of dimension records, NOT IN forces a full nested-loop scan on every batch.
    -- LEFT JOIN + IS NULL is resolved via hash join and benefits from micro-partition pruning
    -- when dim.is_current = TRUE is applied, since most partitions hold historical records.
    MERGE INTO DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM tgt
    USING (
        SELECT DISTINCT
            incoming.raw_payload:"customer_id"::VARCHAR AS missing_customer_id
        FROM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS AS incoming
        LEFT JOIN DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM AS dim
            ON  dim.business_key = incoming.raw_payload:"customer_id"::VARCHAR
            AND dim.is_current   = TRUE   -- prunes to only active-record partitions
        WHERE dim.business_key IS NULL    -- anti-join: only IDs with no active dim record
    ) src
    ON tgt.business_key = src.missing_customer_id
    WHEN NOT MATCHED THEN
        INSERT (
            surrogate_key, business_key, first_name, last_name, email, 
            is_current, valid_from, valid_to, is_deleted, record_checksum,
            created_at, updated_at, source_system, batch_id
        )
        VALUES (
            MD5(src.missing_customer_id || 'GHOST'), 
            src.missing_customer_id, 
            'UNKNOWN_LATE_ARRIVING', -- Placeholder
            'UNKNOWN_LATE_ARRIVING', 
            'UNKNOWN@LATE.ARRIVING',
            TRUE, 
            '1970-01-01'::TIMESTAMP_LTZ, -- Effective since beginning of time
            '9999-12-31'::TIMESTAMP_LTZ, 
            FALSE, 
            'GHOST_CHECKSUM',
            CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'INFERRED_GHOST', SYSTEM$STREAM_GET_JOB_ID()
        );

    RETURN 'Late Arriving Customers successfully inferred.';
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. GHOST DIMENSION PROCEDURE (Product)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_INFER_LATE_PRODUCTS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    -- FIX P2-007: LEFT JOIN anti-join replaces NOT IN for performance at scale.
    MERGE INTO DB_PROD_CURATED.SC_SILVER_PRODUCT.TB_PRODUCT_DIM tgt
    USING (
        SELECT DISTINCT
            incoming.raw_payload:"product_id"::VARCHAR AS missing_product_id
        FROM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDER_ITEMS AS incoming
        LEFT JOIN DB_PROD_CURATED.SC_SILVER_PRODUCT.TB_PRODUCT_DIM AS dim
            ON  dim.business_key = incoming.raw_payload:"product_id"::VARCHAR
            AND dim.is_current   = TRUE
        WHERE dim.business_key IS NULL
    ) src
    ON tgt.business_key = src.missing_product_id
    WHEN NOT MATCHED THEN
        INSERT (
            surrogate_key, business_key, product_name, category, price,
            is_current, valid_from, valid_to, is_deleted, record_checksum,
            created_at, updated_at, source_system, batch_id
        )
        VALUES (
            MD5(src.missing_product_id || 'GHOST'), 
            src.missing_product_id, 
            'UNKNOWN_LATE_ARRIVING', 
            'UNKNOWN', 
            0.00,
            TRUE, '1970-01-01'::TIMESTAMP_LTZ, '9999-12-31'::TIMESTAMP_LTZ, FALSE, 'GHOST_CHECKSUM',
            CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'INFERRED_GHOST', SYSTEM$STREAM_GET_JOB_ID()
        );

    RETURN 'Late Arriving Products successfully inferred.';
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. INTEGRATION INTO TASK DAG (Module 3 Override)
-- ------------------------------------------------------------------------------
-- The Ghost procedures must run before the Fact tables merge, but after the 
-- standard Dimension tables merge (to avoid creating ghosts unnecessarily).
-- 
-- TSK_CDC_CUSTOMER -> TSK_CDC_INFER_GHOSTS -> TSK_CDC_ORDERS

CREATE OR REPLACE TASK TSK_CDC_INFER_GHOSTS
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_CUSTOMER, TSK_CDC_PRODUCT
AS
BEGIN
    CALL SP_INFER_LATE_CUSTOMERS();
    CALL SP_INFER_LATE_PRODUCTS();
END;

-- FIX P0-002: DAG re-wiring is now active. TSK_CDC_ORDERS is decoupled from the
-- direct Customer/Product tasks and now runs AFTER TSK_CDC_INFER_GHOSTS.
-- The AFTER clause on TSK_CDC_ORDERS in 04_tasks.sql handles the new dependency;
-- this task ensures the Ghost node itself is correctly placed between Level-1 dims
-- and the Level-2 fact loads.
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_ORDERS SUSPEND;
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_ORDERS SET AFTER TSK_CDC_INFER_GHOSTS;
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_INFER_GHOSTS RESUME;
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_ORDERS RESUME;
