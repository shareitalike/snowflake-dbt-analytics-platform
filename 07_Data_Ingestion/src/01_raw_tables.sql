-- ==============================================================================
-- 01_raw_tables.sql
-- Description: Bronze layer physical tables designed for Schema-on-Read
-- Phase: 07 - Data Ingestion
-- ==============================================================================

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_RAW;

-- 1. Shopify Orders (JSON Payload)
USE SCHEMA SC_BRONZE_SHOPIFY;
CREATE TABLE IF NOT EXISTS TB_RAW_SHOPIFY_ORDERS (
    raw_payload VARIANT,
    metadata$filename VARCHAR,
    metadata$file_row_number NUMBER,
    ingestion_timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 2. Stripe Payments (JSON Payload)
USE SCHEMA SC_BRONZE_STRIPE;
CREATE TABLE IF NOT EXISTS TB_RAW_STRIPE_PAYMENTS (
    raw_payload VARIANT,
    metadata$filename VARCHAR,
    metadata$file_row_number NUMBER,
    ingestion_timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 3. Oracle ERP Finance (CSV Payload)
-- CSVs are loaded directly into structured columns where possible, but a VARIANT
-- catch-all or raw string columns can be used. We'll use strings to prevent 
-- strict typing failures during COPY INTO.
USE SCHEMA SC_BRONZE_ORACLE_ERP;
CREATE TABLE IF NOT EXISTS TB_RAW_ORACLE_GL (
    account_id VARCHAR,
    period VARCHAR,
    debit_amount VARCHAR,
    credit_amount VARCHAR,
    currency VARCHAR,
    metadata$filename VARCHAR,
    metadata$file_row_number NUMBER,
    ingestion_timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);
