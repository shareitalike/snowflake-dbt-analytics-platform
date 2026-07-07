-- ==============================================================================
-- 01_storage_integrations.sql
-- Description: AWS S3 Storage Integrations (No Static Credentials)
-- ==============================================================================

USE ROLE ACCOUNTADMIN;

-- 1. Create Storage Integration for the Landing Zone and Raw Buckets
CREATE STORAGE INTEGRATION IF NOT EXISTS S3_OMNIRETAIL_PROD_INT
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/omniretail-prod-snowflake-s3-role'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://omniretail-prod-landing-zone/',
        's3://omniretail-prod-raw-data/'
    )
    COMMENT = 'Production AWS S3 Storage Integration';

-- (Post-Deployment Step: Run DESCRIBE INTEGRATION S3_OMNIRETAIL_PROD_INT to retrieve 
-- STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID for the AWS Terraform configuration)

-- 2. Delegate ownership to SYSADMIN
GRANT USAGE ON INTEGRATION S3_OMNIRETAIL_PROD_INT TO ROLE SYSADMIN;
GRANT USAGE ON INTEGRATION S3_OMNIRETAIL_PROD_INT TO ROLE ETL_ADMIN;
