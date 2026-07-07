-- ==============================================================================
-- 02_snowpipes.sql
-- Description: Event-Driven Snowpipe Definitions (Auto-Ingest)
-- Phase: 07 - Data Ingestion
-- ==============================================================================

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
COPY INTO TB_RAW_ORACLE_GL (account_id, period, debit_amount, credit_amount, currency, metadata$filename, metadata$file_row_number)
FROM (
    SELECT 
        $1, $2, $3, $4, $5,
        metadata$filename, 
        metadata$file_row_number 
    FROM @STG_AWS_S3_ORACLE
)
FILE_FORMAT = (FORMAT_NAME = 'DB_PROD_RAW.SC_UTILITIES.FMT_CSV_SKIP_HEADER')
ON_ERROR = CONTINUE;
