-- ==============================================================================
-- 05_late_arriving_tests.sql
-- Description: Unit tests for Late Arriving Data & Ghost Dimensions
-- Phase: 08 - CDC Framework (Module 6)
-- ==============================================================================

USE ROLE DATA_ENGINEER;

-- ==========================================
-- TEST SETUP
-- ==========================================
-- Simulate an incoming order where Customer 'CUST_999' does NOT exist in the Silver layer yet.
INSERT INTO DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS (raw_payload, metadata$filename) 
VALUES (PARSE_JSON('{"order_id": "ORD_123", "customer_id": "CUST_999", "total_amount": 100.00, "updated_at": "2026-07-07T12:00:00Z"}'), 'test_file.json');

-- ==========================================
-- TEST CASE 1: Missing Dimension (Ghost Creation)
-- ==========================================
-- Execute the Inference Procedure
CALL DB_PROD_CURATED.SC_UTILITIES.SP_INFER_LATE_CUSTOMERS();

-- Validation: A Ghost record should now exist in the Silver layer.
SELECT business_key, first_name, source_system, is_current 
FROM DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM 
WHERE business_key = 'CUST_999';
-- EXPECTED RESULT:
-- business_key: CUST_999
-- first_name: UNKNOWN_LATE_ARRIVING
-- source_system: INFERRED_GHOST
-- is_current: TRUE

-- ==========================================
-- TEST CASE 2: Fact Reconciliation (Late Order)
-- ==========================================
-- Now that the Ghost customer exists, the Orders MERGE can execute safely.
CALL DB_PROD_CURATED.SC_UTILITIES.SP_MERGE_ORDERS_TRANSACTIONAL();

-- Validation: Order is successfully inserted and attached to CUST_999.
SELECT order_id, customer_id FROM DB_PROD_CURATED.SC_SILVER_SALES.TB_ORDERS WHERE order_id = 'ORD_123';

-- ==========================================
-- TEST CASE 3: Late Customer Arrival (Overwriting the Ghost)
-- ==========================================
-- The actual Customer payload finally arrives via Snowpipe.
INSERT INTO DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_CUSTOMER (raw_payload, metadata$filename) 
VALUES (PARSE_JSON('{"customer_id": "CUST_999", "first_name": "John", "last_name": "Doe", "email": "john@doe.com", "updated_at": "2026-07-07T12:05:00Z"}'), 'test_file_2.json');

-- Execute the standard Customer SCD2 MERGE (from Module 4)
CALL DB_PROD_CURATED.SC_UTILITIES.SP_MERGE_CUSTOMER_SCD2();

-- Validation: The Ghost record is expired (is_current = FALSE). A new active record with real data is created.
SELECT first_name, source_system, is_current, valid_to 
FROM DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM 
WHERE business_key = 'CUST_999' ORDER BY valid_from DESC;
-- EXPECTED RESULT:
-- Row 1: John | SHOPIFY | TRUE | 9999-12-31
-- Row 2: UNKNOWN_LATE_ARRIVING | INFERRED_GHOST | FALSE | 2026-07-07T12:05:00Z
