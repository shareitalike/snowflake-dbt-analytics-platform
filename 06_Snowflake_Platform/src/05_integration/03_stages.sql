/* ==============================================================================
 * FILE: 03_stages.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Creates external stages linking Snowflake to specific AWS S3 buckets (landing zones) for data ingestion.
 * DESIGN DECISIONS: Binds the previously created Storage Integration to the stages and associates specific pre-defined file formats (JSON, CSV).
 * WHY: Defining external stages with bound file formats and integration roles simplifies the COPY INTO syntax in Snowpipes, moving connection security and formatting logic to the infrastructure layer.
 * ============================================================================== */

USE ROLE ETL_ADMIN;
USE DATABASE DB_PROD_RAW;

-- 1. Shopify Landing Stage
USE SCHEMA SC_BRONZE_SHOPIFY;
CREATE STAGE IF NOT EXISTS STG_AWS_S3_SHOPIFY
    URL = 's3://omniretail-prod-landing-zone/shopify/'
    STORAGE_INTEGRATION = S3_OMNIRETAIL_PROD_INT
    FILE_FORMAT = (FORMAT_NAME = 'DB_PROD_RAW.SC_UTILITIES.FMT_JSON_STRIP_OUTER')
    COMMENT = 'External stage for raw Shopify JSON payloads';

-- 2. Oracle ERP Landing Stage
USE SCHEMA SC_BRONZE_ORACLE_ERP;
CREATE STAGE IF NOT EXISTS STG_AWS_S3_ORACLE
    URL = 's3://omniretail-prod-landing-zone/oracle/'
    STORAGE_INTEGRATION = S3_OMNIRETAIL_PROD_INT
    FILE_FORMAT = (FORMAT_NAME = 'DB_PROD_RAW.SC_UTILITIES.FMT_CSV_SKIP_HEADER')
    COMMENT = 'External stage for raw Oracle ERP CSV extracts';

-- 3. Stripe Landing Stage
USE SCHEMA SC_BRONZE_STRIPE;
CREATE STAGE IF NOT EXISTS STG_AWS_S3_STRIPE
    URL = 's3://omniretail-prod-landing-zone/stripe/'
    STORAGE_INTEGRATION = S3_OMNIRETAIL_PROD_INT
    FILE_FORMAT = (FORMAT_NAME = 'DB_PROD_RAW.SC_UTILITIES.FMT_JSON_STRIP_OUTER')
    COMMENT = 'External stage for Stripe payment payloads';
