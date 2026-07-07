-- ==============================================================================
-- 03_stages.sql
-- Description: External Stages for Data Ingestion
-- ==============================================================================

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
