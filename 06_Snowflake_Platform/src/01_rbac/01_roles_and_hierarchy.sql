-- ==============================================================================
-- 01_roles_and_hierarchy.sql
-- Description: Enterprise Role-Based Access Control (RBAC) Hierarchy
-- ==============================================================================

USE ROLE ACCOUNTADMIN;

-- 1. System Role Delegation
GRANT ROLE SYSADMIN TO ROLE ACCOUNTADMIN;
GRANT ROLE SECURITYADMIN TO ROLE ACCOUNTADMIN;

-- 2. Functional Roles Creation
USE ROLE SECURITYADMIN;

-- Engineering Roles
CREATE ROLE IF NOT EXISTS ETL_ADMIN COMMENT = 'Manages ingestion and external stages';
CREATE ROLE IF NOT EXISTS DATA_ENGINEER COMMENT = 'Manages Silver layer and Snowpark logic';
CREATE ROLE IF NOT EXISTS ANALYTICS_ENGINEER COMMENT = 'Manages Gold dimensional modeling via dbt';

-- Consumption Roles
CREATE ROLE IF NOT EXISTS BI_DEVELOPER COMMENT = 'Manages Power BI Semantic Layers';
CREATE ROLE IF NOT EXISTS BUSINESS_ANALYST COMMENT = 'Exploratory data analysis on Gold views';
CREATE ROLE IF NOT EXISTS READ_ONLY COMMENT = 'Strictly read-only access for executives';

-- Service Roles
CREATE ROLE IF NOT EXISTS AIRFLOW_SERVICE COMMENT = 'Automated orchestration service role';
CREATE ROLE IF NOT EXISTS DBT_SERVICE COMMENT = 'Automated CI/CD transformation role';

-- 3. Role Hierarchy Inheritance
-- SYSADMIN owns everything.
GRANT ROLE ETL_ADMIN TO ROLE SYSADMIN;
GRANT ROLE DATA_ENGINEER TO ROLE SYSADMIN;
GRANT ROLE ANALYTICS_ENGINEER TO ROLE SYSADMIN;
GRANT ROLE BI_DEVELOPER TO ROLE SYSADMIN;

-- Service Accounts inherit from Engineering
GRANT ROLE AIRFLOW_SERVICE TO ROLE ETL_ADMIN;
GRANT ROLE DBT_SERVICE TO ROLE ANALYTICS_ENGINEER;

-- Consumption Roles Chain
GRANT ROLE BUSINESS_ANALYST TO ROLE BI_DEVELOPER;
GRANT ROLE READ_ONLY TO ROLE BUSINESS_ANALYST;
