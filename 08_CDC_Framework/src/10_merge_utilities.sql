-- ==============================================================================
-- 10_merge_utilities.sql
-- Description: Reusable Audit Framework and Validation logic
-- Phase: 08 - CDC Framework (Module 4)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_CURATED;
USE SCHEMA SC_UTILITIES;

-- ------------------------------------------------------------------------------
-- 1. Checksum Generation UDF
-- ------------------------------------------------------------------------------
-- Centralizes the hashing logic to ensure consistency across all models
CREATE OR REPLACE FUNCTION FN_GENERATE_RECORD_CHECKSUM(payload VARIANT)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
  // In a real scenario, we might sort JSON keys deterministically, 
  // but for simplicity in Snowflake SQL, MD5 on the VARIANT string cast works.
  return '<Hash Implementation>';
$$;

-- ------------------------------------------------------------------------------
-- 2. Validation Queries (Data Quality)
-- ------------------------------------------------------------------------------

-- Identify Duplicate Active SCD2 Records
-- Returns results if the MERGE framework failed idempotency guarantees.
CREATE OR REPLACE SECURE VIEW VW_DQ_DUPLICATE_ACTIVE_CUSTOMERS AS
SELECT business_key, COUNT(*) as Active_Versions
FROM DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM
WHERE is_current = TRUE
GROUP BY business_key
HAVING COUNT(*) > 1;

-- Identify Overlapping Validity Windows
CREATE OR REPLACE SECURE VIEW VW_DQ_OVERLAPPING_VALIDITY_WINDOWS AS
SELECT 
    a.business_key, 
    a.surrogate_key as current_sk, 
    b.surrogate_key as next_sk
FROM DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM a
JOIN DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM b 
  ON a.business_key = b.business_key
 AND a.surrogate_key != b.surrogate_key
 AND b.valid_from >= a.valid_from
 AND b.valid_from < a.valid_to;
