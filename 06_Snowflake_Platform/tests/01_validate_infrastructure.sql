/* ==============================================================================
 * FILE: 01_validate_infrastructure.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Provides a suite of validation queries to ensure the Snowflake platform infrastructure and RBAC adhere to architectural standards post-deployment.
 * DESIGN DECISIONS: Checks role existence, warehouse configuration (AUTO_SUSPEND), Resource Monitor attachment, and Database Time Travel retention periods.
 * WHY: Validating infrastructure acts as a manual integration test during deployment or audits, ensuring cost optimizations (like 60s auto-suspend and 1-day retention for raw DBs) were correctly applied.
 * ============================================================================== */

USE ROLE ACCOUNTADMIN;

-- 1. Validate Roles Exist
SHOW ROLES LIKE 'DBT_SERVICE';
SHOW ROLES LIKE 'AIRFLOW_SERVICE';
SHOW ROLES LIKE 'ANALYTICS_ENGINEER';

-- 2. Validate Warehouses Exist and Auto-Suspend is set to 60s
SHOW WAREHOUSES;
-- (Review AUTO_SUSPEND column to ensure no warehouse is running indefinitely)

-- 3. Validate Resource Monitors are attached
SHOW RESOURCE MONITORS;
-- (Review WAREHOUSE mapping to ensure WH_DBT and WH_BI are capped)

-- 4. Validate DB Retention (Time Travel)
SHOW DATABASES LIKE 'DB_PROD_%';
-- DB_PROD_ANALYTICS should show retention_time = 90
-- DB_PROD_RAW should show retention_time = 1

-- 5. Validate Role Hierarchy
-- Execute as SYSADMIN to ensure they can see the created databases.
USE ROLE SYSADMIN;
SHOW DATABASES;
-- Expected: DB_PROD_RAW, DB_PROD_CURATED, DB_PROD_ANALYTICS are visible.
