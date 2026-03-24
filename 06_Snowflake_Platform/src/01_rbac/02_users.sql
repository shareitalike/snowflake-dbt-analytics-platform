/* ==============================================================================
 * FILE: 02_users.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Provisions service accounts for automated orchestration and CI/CD tools, assigning them their respective default roles.
 * DESIGN DECISIONS: Disables password authentication (MUST_CHANGE_PASSWORD = FALSE) because these accounts rely exclusively on Key-Pair Authentication for programmatic access.
 * WHY: Key-Pair authentication provides a vastly superior security posture compared to basic passwords, immune to credential stuffing, and aligns with zero-trust enterprise security standards.
 * ============================================================================== */

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
