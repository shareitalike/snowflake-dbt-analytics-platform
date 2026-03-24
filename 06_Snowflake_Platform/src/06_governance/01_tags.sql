/* ==============================================================================
 * FILE: 01_tags.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Implements object tagging for cost attribution and data classification governance.
 * DESIGN DECISIONS: Creates constrained TAG_COST_CENTER and TAG_DATA_CLASSIFICATION tags with allowed values, then applies the cost tags directly to virtual warehouses.
 * WHY: Cost center tags enable precise FinOps chargebacks to business units (e.g., Executive vs Engineering). Data classification tags are crucial for identifying PII and ensuring compliance audits run smoothly.
 * ============================================================================== */

USE ROLE SECURITYADMIN;
USE DATABASE DB_PROD_GOVERNANCE;
USE SCHEMA SC_GOV_TAGS;

-- 1. Cost Center Tags (For Financial Chargebacks)
CREATE TAG IF NOT EXISTS TAG_COST_CENTER
    ALLOWED_VALUES 'MARKETING', 'FINANCE', 'ENGINEERING', 'EXECUTIVE', 'DATA_SCIENCE'
    COMMENT = 'Used for tagging warehouses and databases to track credit spend';

-- 2. Data Classification Tags (For PII/Compliance Tracking)
CREATE TAG IF NOT EXISTS TAG_DATA_CLASSIFICATION
    ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED', 'PII', 'PCI'
    COMMENT = 'Used for identifying sensitive data columns across the enterprise';

-- Apply tags to Warehouses (Requires ACCOUNTADMIN to apply to account-level objects)
USE ROLE ACCOUNTADMIN;
ALTER WAREHOUSE WH_BI SET TAG DB_PROD_GOVERNANCE.SC_GOV_TAGS.TAG_COST_CENTER = 'EXECUTIVE';
ALTER WAREHOUSE WH_DBT SET TAG DB_PROD_GOVERNANCE.SC_GOV_TAGS.TAG_COST_CENTER = 'ENGINEERING';
