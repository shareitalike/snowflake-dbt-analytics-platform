/* ==============================================================================
 * FILE: 03_row_access_policies.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Configures Row Access Policies (RAP) for multi-tenant regional data masking to ensure users only see data they are entitled to.
 * DESIGN DECISIONS: Uses a mapping table (TB_ENTITLEMENT_REGION) to link roles to allowed regions. The policy dynamically checks this table against CURRENT_ROLE() and the row's region value.
 * WHY: Data localization laws (like GDPR) require strict regional access controls. The mapping table approach is highly scalable, allowing administrators to update entitlements via simple INSERTs rather than hardcoding roles in the policy logic.
 * ============================================================================== */

USE ROLE SECURITYADMIN;
USE DATABASE DB_PROD_GOVERNANCE;
USE SCHEMA SC_GOV_POLICIES;

-- 1. Regional Entitlement Mapping Table
USE SCHEMA SC_GOV_MAPPINGS;
CREATE TABLE IF NOT EXISTS TB_ENTITLEMENT_REGION (
    ROLE_NAME VARCHAR(100),
    REGION_NAME VARCHAR(100)
);

-- Insert mappings
INSERT INTO TB_ENTITLEMENT_REGION (ROLE_NAME, REGION_NAME) VALUES 
('BUSINESS_ANALYST_EMEA', 'EMEA'),
('BUSINESS_ANALYST_NA', 'NA'),
('BUSINESS_ANALYST_APAC', 'APAC'),
('EXECUTIVE_GLOBAL', 'ALL');

-- 2. Row Access Policy Definition
USE SCHEMA SC_GOV_POLICIES;
CREATE ROW ACCESS POLICY IF NOT EXISTS POL_RAP_REGION AS (region_val VARCHAR) RETURNS BOOLEAN ->
    -- Allow ACCOUNTADMIN or DATA_STEWARD full access
    CURRENT_ROLE() IN ('ACCOUNTADMIN', 'DATA_STEWARD')
    OR
    -- Check mapping table
    EXISTS (
        SELECT 1 FROM DB_PROD_GOVERNANCE.SC_GOV_MAPPINGS.TB_ENTITLEMENT_REGION
        WHERE ROLE_NAME = CURRENT_ROLE()
        AND (REGION_NAME = region_val OR REGION_NAME = 'ALL')
    );

-- Note: This RAP will be applied to the Gold dimension views (e.g., VW_SEC_STORE_DIM) via dbt.
