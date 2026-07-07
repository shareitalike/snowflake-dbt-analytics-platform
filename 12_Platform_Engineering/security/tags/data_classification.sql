/* ==============================================================================
 * FILE: data_classification.sql
 * PHASE: 12 - Platform Engineering
 * 
 * EXPLANATION: Establishes object tags for Data Classification (e.g., PII, Sensitivity Levels) used for automated governance and dynamic data masking.
 * DESIGN DECISIONS: Centralizes tag creation under a dedicated GOVERNANCE_DB and assigns management to a unified DATA_GOVERNANCE_OFFICER role.
 * WHY: Tagging data at the column level enables Snowflake to automatically apply Dynamic Data Masking policies (e.g., masking emails for Analysts but showing them to HR) without writing complex views for every table.
 * ============================================================================== */

USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS GOVERNANCE_DB;
CREATE SCHEMA IF NOT EXISTS GOVERNANCE_DB.TAGS;
USE SCHEMA GOVERNANCE_DB.TAGS;

-- 1. Create Data Privacy Tags
CREATE OR REPLACE TAG PII_DATA
  ALLOWED_VALUES 'EMAIL', 'SSN', 'PHONE', 'ADDRESS'
  COMMENT = 'Tag for Personally Identifiable Information';

CREATE OR REPLACE TAG SENSITIVITY_LEVEL
  ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED'
  COMMENT = 'Data Classification Sensitivity Level';

-- 2. Apply Tags to specific objects (Example)
-- ALTER TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER MODIFY COLUMN EMAIL SET TAG PII_DATA = 'EMAIL';
-- ALTER TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER MODIFY COLUMN EMAIL SET TAG SENSITIVITY_LEVEL = 'RESTRICTED';

-- 3. Create a unified Governance Role
CREATE ROLE IF NOT EXISTS DATA_GOVERNANCE_OFFICER;
GRANT USAGE ON DATABASE GOVERNANCE_DB TO ROLE DATA_GOVERNANCE_OFFICER;
GRANT USAGE ON SCHEMA GOVERNANCE_DB.TAGS TO ROLE DATA_GOVERNANCE_OFFICER;
GRANT APPLY ON TAG PII_DATA TO ROLE DATA_GOVERNANCE_OFFICER;
