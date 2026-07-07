/* ==============================================================================
 * FILE: role_hierarchy.sql
 * PHASE: 12 - Platform Engineering
 * 
 * EXPLANATION: Defines the Role-Based Access Control (RBAC) hierarchy, separating System roles, Functional (Human) roles, and Service (Machine) roles.
 * DESIGN DECISIONS: Enforces inheritance where Machine roles roll up into the Engineering role for visibility. Strictly adheres to Least Privilege by granting Analysts access only to the GOLD layer.
 * WHY: A poorly designed RBAC model leads to "role explosion" and security gaps. Separating machine and human roles ensures service accounts aren't used for interactive querying, and inheritance simplifies permission management.
 * ============================================================================== */

USE ROLE SECURITYADMIN;

-- 1. System Roles (Managed by Cloud/Platform teams)
CREATE ROLE IF NOT EXISTS PROD_SYSADMIN_ROLE;
CREATE ROLE IF NOT EXISTS PROD_SECURITYADMIN_ROLE;

-- 2. Functional Roles (Used by humans via SSO)
CREATE ROLE IF NOT EXISTS PROD_DATA_ENGINEER_ROLE;
CREATE ROLE IF NOT EXISTS PROD_DATA_ANALYST_ROLE;
CREATE ROLE IF NOT EXISTS PROD_DATA_SCIENTIST_ROLE;

-- 3. Service Roles (Used by Machines/Service Accounts, No UI Login)
CREATE ROLE IF NOT EXISTS SVC_AIRFLOW_ROLE;
CREATE ROLE IF NOT EXISTS SVC_DBT_CLOUD_ROLE;
CREATE ROLE IF NOT EXISTS SVC_FIVETRAN_ROLE;
CREATE ROLE IF NOT EXISTS SVC_POWERBI_ROLE;

-- 4. Role Hierarchy (Inheritance)
-- All Machine Roles roll up into the Engineering Role for visibility
GRANT ROLE SVC_AIRFLOW_ROLE TO ROLE PROD_DATA_ENGINEER_ROLE;
GRANT ROLE SVC_DBT_CLOUD_ROLE TO ROLE PROD_DATA_ENGINEER_ROLE;
GRANT ROLE SVC_FIVETRAN_ROLE TO ROLE PROD_DATA_ENGINEER_ROLE;

-- Functional Roles roll up to System Admin
GRANT ROLE PROD_DATA_ENGINEER_ROLE TO ROLE PROD_SYSADMIN_ROLE;
GRANT ROLE PROD_DATA_ANALYST_ROLE TO ROLE PROD_SYSADMIN_ROLE;
GRANT ROLE PROD_DATA_SCIENTIST_ROLE TO ROLE PROD_SYSADMIN_ROLE;

-- 5. Least Privilege Assignments
-- Analysts can only SELECT from the GOLD layer. They cannot see BRONZE/SILVER.
-- (Assuming OMNIRETAIL.GOLD exists)
GRANT USAGE ON DATABASE OMNIRETAIL TO ROLE PROD_DATA_ANALYST_ROLE;
GRANT USAGE ON SCHEMA OMNIRETAIL.GOLD TO ROLE PROD_DATA_ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA OMNIRETAIL.GOLD TO ROLE PROD_DATA_ANALYST_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA OMNIRETAIL.GOLD TO ROLE PROD_DATA_ANALYST_ROLE;
