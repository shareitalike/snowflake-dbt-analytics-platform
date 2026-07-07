-- ==============================================================================
-- 01_stream_tests.sql
-- Description: Validation scripts and test cases for CDC streams
-- Phase: 08 - CDC Framework (Module 2)
-- ==============================================================================

USE ROLE DATA_ENGINEER;

-- ==========================================
-- TEST CASE 1: Verify Stream Creation & Type
-- ==========================================
SHOW STREAMS IN DATABASE DB_PROD_RAW;
-- VALIDATION: Ensure `mode` column matches APPEND_ONLY for Shopify/Stripe/POS 
-- and DEFAULT (Standard) for Oracle ERP.

-- ==========================================
-- TEST CASE 2: Append-Only Stream Behavior
-- ==========================================
USE SCHEMA DB_PROD_RAW.SC_BRONZE_SHOPIFY;
-- Setup Test Data
INSERT INTO TB_RAW_SHOPIFY_ORDERS (raw_payload, metadata$filename) 
VALUES (PARSE_JSON('{"order_id": 999, "status": "pending"}'), 'test_file.json');

-- Verify Stream has data (Should return TRUE)
SELECT SYSTEM$STREAM_HAS_DATA('STR_SHOPIFY_ORDERS');

-- Consume Stream (Simulate Task execution)
-- Note: Starting a transaction locks the stream offset.
BEGIN;
  CREATE TEMPORARY TABLE TMP_CDC_CONSUME AS 
  SELECT * FROM STR_SHOPIFY_ORDERS;
COMMIT;

-- Verify Stream is empty (Should return FALSE)
SELECT SYSTEM$STREAM_HAS_DATA('STR_SHOPIFY_ORDERS');

-- Attempt an UPDATE on the base table (Should fail for Append-Only streams unless specifically configured, 
-- or it simply won't track the UPDATE in the stream).
UPDATE TB_RAW_SHOPIFY_ORDERS 
SET raw_payload = PARSE_JSON('{"order_id": 999, "status": "shipped"}') 
WHERE metadata$filename = 'test_file.json';

-- Check Stream: Because it is APPEND_ONLY, this update is ignored by the stream.
SELECT count(*) FROM STR_SHOPIFY_ORDERS; -- Expected: 0

-- ==========================================
-- TEST CASE 3: Standard Stream Behavior
-- ==========================================
USE SCHEMA DB_PROD_RAW.SC_BRONZE_ORACLE_ERP;
-- Setup
INSERT INTO TB_RAW_ORACLE_SUPPLIER (account_id) VALUES ('SUP_001');

-- Consume Insert
BEGIN;
  SELECT * FROM STR_ORACLE_SUPPLIER; -- consumes the offset
COMMIT;

-- Update Record
UPDATE TB_RAW_ORACLE_SUPPLIER SET currency = 'USD' WHERE account_id = 'SUP_001';

-- Check Stream (Standard streams track the update as a pair of DELETE and INSERT)
SELECT METADATA$ACTION, METADATA$ISUPDATE, account_id 
FROM STR_ORACLE_SUPPLIER;
-- Expected: 
-- METADATA$ACTION='DELETE', METADATA$ISUPDATE=TRUE
-- METADATA$ACTION='INSERT', METADATA$ISUPDATE=TRUE
