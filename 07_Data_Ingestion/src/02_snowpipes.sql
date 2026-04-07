/* ==============================================================================
 * FILE: 02_snowpipes.sql
 * PHASE: 07 - Data Ingestion
 * 
 * EXPLANATION: Configures event-driven Snowpipes to automatically ingest data from AWS S3 external stages into the bronze tables.
 * DESIGN DECISIONS: Leverages AUTO_INGEST = TRUE linked to an AWS SNS topic. Uses ON_ERROR = CONTINUE for fault tolerance. File formats strip outer arrays for JSON and skip headers for CSVs.
 * WHY: AUTO_INGEST provides near real-time data availability without the overhead of scheduling manual batch jobs. ON_ERROR = CONTINUE ensures that one malformed record doesn't block the entire micro-batch, allowing valid data to flow through while bad data is isolated.
 * ============================================================================== */

USE ROLE ETL_ADMIN;
USE DATABASE DB_PROD_RAW;

-- NOTE: The AWS_SNS_TOPIC requires the exact ARN from Phase 05 Terraform outputs.

-- 1. Shopify Snowpipe
USE SCHEMA SC_BRONZE_SHOPIFY;
CREATE OR REPLACE PIPE PIP_SHOPIFY_ORDERS
    AUTO_INGEST = TRUE
    AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:123456789012:omniretail-prod-snowpipe-notifications'
AS
COPY INTO TB_RAW_SHOPIFY_ORDERS (raw_payload, metadata$filename, metadata$file_row_number)
FROM (
    SELECT 
        $1, 
        metadata$filename, 
        metadata$file_row_number 
    FROM @STG_AWS_S3_SHOPIFY
)
FILE_FORMAT = (FORMAT_NAME = 'DB_PROD_RAW.SC_UTILITIES.FMT_JSON_STRIP_OUTER')
ON_ERROR = CONTINUE; 
-- (ON_ERROR = CONTINUE guarantees 1 bad record doesn't block the micro-batch)

-- 2. Stripe Snowpipe
USE SCHEMA SC_BRONZE_STRIPE;
CREATE OR REPLACE PIPE PIP_STRIPE_PAYMENTS
    AUTO_INGEST = TRUE
    AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:123456789012:omniretail-prod-snowpipe-notifications'
AS
COPY INTO TB_RAW_STRIPE_PAYMENTS (raw_payload, metadata$filename, metadata$file_row_number)
FROM (
    SELECT 
        $1, 
        metadata$filename, 
        metadata$file_row_number 
    FROM @STG_AWS_S3_STRIPE
)
FILE_FORMAT = (FORMAT_NAME = 'DB_PROD_RAW.SC_UTILITIES.FMT_JSON_STRIP_OUTER')
ON_ERROR = CONTINUE;

-- 3. Oracle ERP Snowpipe (CSV)
USE SCHEMA SC_BRONZE_ORACLE_ERP;
CREATE OR REPLACE PIPE PIP_ORACLE_GL
    AUTO_INGEST = TRUE
    AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:123456789012:omniretail-prod-snowpipe-notifications'
AS
COPY INTO TB_RAW_ORACLE_GL
FROM @STG_AWS_S3_ORACLE
FILE_FORMAT = (FORMAT_NAME = 'DB_PROD_RAW.SC_UTILITIES.FMT_CSV_WITH_HEADER')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = CONTINUE;
