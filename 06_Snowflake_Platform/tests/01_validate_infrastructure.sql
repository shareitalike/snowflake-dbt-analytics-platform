-- ==============================================================================
-- 01_validate_infrastructure.sql
-- Description: Validates RBAC and Infrastructure against architectural standards
-- Phase: 06 - Snowflake Platform Implementation
-- ==============================================================================

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
