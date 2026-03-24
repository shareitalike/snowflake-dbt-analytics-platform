/* ==============================================================================
 * FILE: 01_storage_integrations.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Creates an AWS S3 Storage Integration to establish a secure trust relationship between Snowflake and AWS without hardcoding static credentials.
 * DESIGN DECISIONS: Uses STORAGE_AWS_ROLE_ARN and restricts access exclusively to specific landing zone and raw data buckets via STORAGE_ALLOWED_LOCATIONS.
 * WHY: Replacing static AWS Access Keys with IAM Role assumption (Storage Integrations) eliminates credential rotation overhead and prevents data breaches caused by leaked keys in code repositories.
 * ============================================================================== */

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
