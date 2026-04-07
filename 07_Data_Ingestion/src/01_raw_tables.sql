/* ==============================================================================
 * FILE: 01_raw_tables.sql
 * PHASE: 07 - Data Ingestion
 * 
 * EXPLANATION: Defines the initial bronze layer tables for Shopify, Stripe, and Oracle ERP data ingestion.
 * DESIGN DECISIONS: Utilizes VARIANT data type for JSON payloads (Schema-on-Read) and standard VARCHAR for CSV data to prevent strict typing failures during the COPY INTO process. Captures metadata like filename, row number, and ingestion timestamp.
 * WHY: Using VARIANT for JSON allows the system to gracefully handle upstream schema changes without pipeline breakage. CSVs use VARCHAR instead of VARIANT because CSVs are inherently flat; mapping them to VARCHAR columns leverages Snowflake's native columnar storage for better query performance and avoids the compute overhead of forcing flat data into a semi-structured container during COPY INTO. Capturing file metadata is crucial for data lineage, auditing, and debugging ingestion issues.
 * ============================================================================== */

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
    metadata_filename VARCHAR DEFAULT METADATA$FILENAME,
    metadata_file_row_number NUMBER DEFAULT METADATA$FILE_ROW_NUMBER,
    ingestion_timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);
