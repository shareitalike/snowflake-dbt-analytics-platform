/* ==============================================================================
 * FILE: 01_ingestion_tests.sql
 * PHASE: 07 - Data Ingestion
 * 
 * EXPLANATION: Provides a suite of SQL statements to test and validate Snowpipe configurations, external stage connectivity, and DLQ routing.
 * DESIGN DECISIONS: Uses SYSTEM$PIPE_STATUS to check running state, VALIDATE function to preview errors without querying DLQ directly, and VALIDATION_MODE = 'RETURN_ERRORS' for dry runs.
 * WHY: Equips data engineers with immediate troubleshooting commands to verify infrastructure setup during CI/CD or post-incident analysis, ensuring reliable pipeline recovery.
 * ============================================================================== */

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_RAW;
USE SCHEMA SC_BRONZE_SHOPIFY;

-- 1. Validate Pipe Configuration
-- Ensure the pipe is properly connected to the SNS topic and is RUNNING.
SELECT SYSTEM$PIPE_STATUS('PIP_SHOPIFY_ORDERS');
-- Expected Output should include: {"executionState":"RUNNING"}

-- 2. Validate Bad File Handling via VALIDATE function
-- This allows developers to see what WOULD have failed without querying the DLQ directly.
SELECT * FROM TABLE(VALIDATE(TB_RAW_SHOPIFY_ORDERS, JOB_ID => '_last'));

-- 3. Dry Run COPY INTO (Testing external stage connectivity)
COPY INTO TB_RAW_SHOPIFY_ORDERS
FROM @STG_AWS_S3_SHOPIFY
VALIDATION_MODE = 'RETURN_ERRORS';

-- 4. DLQ Routing Test
-- Verify that the stored procedure caught failed files in the last hour.
SELECT COUNT(*) 
FROM DB_PROD_RAW.SC_BRONZE_QUARANTINE.TB_DLQ_PAYLOADS
WHERE Quarantine_Time > DATEADD(hour, -1, CURRENT_TIMESTAMP());
