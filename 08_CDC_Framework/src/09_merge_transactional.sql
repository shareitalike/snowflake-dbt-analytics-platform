/* ==============================================================================
 * FILE: 09_merge_transactional.sql
 * PHASE: 08 - CDC Framework (Module 4)
 * 
 * EXPLANATION: Performs append and update logic for transactional fact data (Orders), merging from the raw stream into the curated Silver layer.
 * DESIGN DECISIONS: Deduplicates the raw stream using QUALIFY ROW_NUMBER() OVER (...). Handles late-arriving updates by comparing source_updated_at timestamps to ensure older payloads don't overwrite newer state.
 * WHY: Transactional data often requires late-arriving updates (e.g., an order changing from 'PENDING' to 'SHIPPED'). The timestamp comparison guarantees idempotency and correct state resolution even if stream data arrives out of order.
 * ============================================================================== */

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_CURATED;
USE SCHEMA SC_UTILITIES;
-- ------------------------------------------------------------------------------
-- REUSABLE PROCEDURE: Transactional MERGE (Orders)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_MERGE_ORDERS_TRANSACTIONAL()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    MERGE INTO DB_PROD_CURATED.SC_SILVER_SALES.TB_ORDERS tgt
    USING (
        SELECT 
            raw_payload:"order_id"::VARCHAR AS order_id,
            raw_payload:"customer_id"::VARCHAR AS customer_id,
            raw_payload:"total_amount"::NUMBER(38,2) AS total_amount,
            raw_payload:"status"::VARCHAR AS status,
            raw_payload:"updated_at"::TIMESTAMP_LTZ AS source_updated_at,
            raw_payload:"is_deleted"::BOOLEAN AS is_deleted
        FROM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS
        QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY source_updated_at DESC) = 1
    ) src
    ON tgt.order_id = src.order_id
    
    -- Handle Late Arriving Updates
    WHEN MATCHED AND src.source_updated_at > tgt.source_updated_at THEN
        UPDATE SET 
            tgt.status = src.status,
            tgt.total_amount = src.total_amount,
            tgt.is_deleted = NVL(src.is_deleted, FALSE),
            tgt.updated_at = CURRENT_TIMESTAMP(),
            tgt.batch_id = SYSTEM$STREAM_GET_JOB_ID()
            
    -- Handle Net-New Orders
    WHEN NOT MATCHED THEN
        INSERT (
            order_id, customer_id, total_amount, status, 
            source_updated_at, is_deleted, created_at, updated_at, source_system
        )
        VALUES (
            src.order_id, src.customer_id, src.total_amount, src.status,
            src.source_updated_at, NVL(src.is_deleted, FALSE), 
            CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 'SHOPIFY_ORDERS'
        );

    RETURN 'Successfully merged Transactional Orders';
END;
$$;
