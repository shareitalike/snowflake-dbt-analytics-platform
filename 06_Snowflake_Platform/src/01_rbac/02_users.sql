-- ==============================================================================
-- 02_users.sql
-- Description: Provisioning Service Accounts and Key-Pair Authentication
-- ==============================================================================

USE ROLE SECURITYADMIN;

-- Service Accounts (Key-Pair Authentication Enforced in Production)
CREATE USER IF NOT EXISTS SVC_AIRFLOW
    DEFAULT_ROLE = AIRFLOW_SERVICE
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT = 'Service account for Apache Airflow Orchestration';

CREATE USER IF NOT EXISTS SVC_DBT_CLOUD
    DEFAULT_ROLE = DBT_SERVICE
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT = 'Service account for dbt Cloud CI/CD and deployments';

-- Grant Roles to Users
GRANT ROLE AIRFLOW_SERVICE TO USER SVC_AIRFLOW;
GRANT ROLE DBT_SERVICE TO USER SVC_DBT_CLOUD;

-- Note: Human users will be provisioned automatically via Azure AD / SCIM integration.
