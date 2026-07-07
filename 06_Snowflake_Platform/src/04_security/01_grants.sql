-- ==============================================================================
-- 01_grants.sql
-- Description: Enforcing Least Privilege Access Rights
-- ==============================================================================

USE ROLE SECURITYADMIN;

-- ------------------------------------------------------------------------------
-- DATABASE USAGE GRANTS
-- ------------------------------------------------------------------------------
GRANT USAGE ON DATABASE DB_PROD_RAW TO ROLE DBT_SERVICE;
GRANT USAGE ON DATABASE DB_PROD_RAW TO ROLE DATA_ENGINEER;

GRANT USAGE ON DATABASE DB_PROD_CURATED TO ROLE DBT_SERVICE;
GRANT USAGE ON DATABASE DB_PROD_CURATED TO ROLE DATA_ENGINEER;
GRANT USAGE ON DATABASE DB_PROD_CURATED TO ROLE ANALYTICS_ENGINEER;

GRANT USAGE ON DATABASE DB_PROD_ANALYTICS TO ROLE DBT_SERVICE;
GRANT USAGE ON DATABASE DB_PROD_ANALYTICS TO ROLE ANALYTICS_ENGINEER;
GRANT USAGE ON DATABASE DB_PROD_ANALYTICS TO ROLE BI_DEVELOPER;
GRANT USAGE ON DATABASE DB_PROD_ANALYTICS TO ROLE BUSINESS_ANALYST;

-- ------------------------------------------------------------------------------
-- SCHEMA USAGE GRANTS
-- ------------------------------------------------------------------------------
-- Note: In a real deployment, these would be explicitly iterated across all schemas.
GRANT USAGE ON ALL SCHEMAS IN DATABASE DB_PROD_RAW TO ROLE DBT_SERVICE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE DB_PROD_CURATED TO ROLE DBT_SERVICE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE DB_PROD_ANALYTICS TO ROLE DBT_SERVICE;

-- Analysts can only see the Gold layer schemas
GRANT USAGE ON SCHEMA DB_PROD_ANALYTICS.SC_GOLD_CORE TO ROLE BI_DEVELOPER;
GRANT USAGE ON SCHEMA DB_PROD_ANALYTICS.SC_GOLD_CORE TO ROLE BUSINESS_ANALYST;

-- ------------------------------------------------------------------------------
-- TABLE READ/WRITE GRANTS
-- ------------------------------------------------------------------------------
-- DBT_SERVICE has full DML capabilities in Curated and Analytics
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN DATABASE DB_PROD_CURATED TO ROLE DBT_SERVICE;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN DATABASE DB_PROD_ANALYTICS TO ROLE DBT_SERVICE;

-- Analysts can only SELECT from views in Gold, never direct tables
GRANT SELECT ON ALL VIEWS IN SCHEMA DB_PROD_ANALYTICS.SC_GOLD_EXECUTIVE TO ROLE BUSINESS_ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA DB_PROD_ANALYTICS.SC_GOLD_MARKETING TO ROLE BUSINESS_ANALYST;
