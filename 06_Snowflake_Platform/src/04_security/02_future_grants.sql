-- ==============================================================================
-- 02_future_grants.sql
-- Description: Future Grants to enable seamless CI/CD model deployment
-- ==============================================================================

USE ROLE SECURITYADMIN;

-- Future Grants ensure that when dbt Cloud drops and recreates a table/view,
-- the BI_DEVELOPER and BUSINESS_ANALYST roles do not lose access to it.

-- DBT Service Future Grants (Write Access)
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON FUTURE TABLES IN DATABASE DB_PROD_CURATED TO ROLE DBT_SERVICE;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON FUTURE TABLES IN DATABASE DB_PROD_ANALYTICS TO ROLE DBT_SERVICE;

-- Analyst Future Grants (Read Access on Views Only)
GRANT SELECT ON FUTURE VIEWS IN SCHEMA DB_PROD_ANALYTICS.SC_GOLD_CORE TO ROLE BI_DEVELOPER;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA DB_PROD_ANALYTICS.SC_GOLD_CORE TO ROLE BUSINESS_ANALYST;

GRANT SELECT ON FUTURE VIEWS IN SCHEMA DB_PROD_ANALYTICS.SC_GOLD_EXECUTIVE TO ROLE BUSINESS_ANALYST;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA DB_PROD_ANALYTICS.SC_GOLD_MARKETING TO ROLE BUSINESS_ANALYST;
