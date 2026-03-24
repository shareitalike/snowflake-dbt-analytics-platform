/* ==============================================================================
 * FILE: 02_masking_policies.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Defines Dynamic Data Masking (DDM) policies to obfuscate PII and PCI data (Emails, Phones, Credit Cards).
 * DESIGN DECISIONS: Uses conditional CASE logic evaluating CURRENT_ROLE() to return plaintext for DATA_STEWARD and ACCOUNTADMIN, while hashing or masking strings for all other roles.
 * WHY: Dynamic Data Masking prevents sensitive data exposure to unauthorized users without needing to create separate, physically masked copies of the data, vastly simplifying compliance.
 * ============================================================================== */

USE ROLE SECURITYADMIN;
USE DATABASE DB_PROD_GOVERNANCE;
USE SCHEMA SC_GOV_POLICIES;

-- 1. Email Masking Policy
-- Logic: DATA_STEWARD sees plaintext. Everyone else sees SHA256 hashed emails.
CREATE MASKING POLICY IF NOT EXISTS POL_MASK_EMAIL AS (val string) RETURNS string ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_STEWARD', 'ACCOUNTADMIN') THEN val
        ELSE SHA2(val, 256)
    END;

-- 2. Phone Number Masking Policy
-- Logic: Mask to XXX-XXX-1234
CREATE MASKING POLICY IF NOT EXISTS POL_MASK_PHONE AS (val string) RETURNS string ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_STEWARD', 'ACCOUNTADMIN') THEN val
        ELSE '***-***-' || RIGHT(val, 4)
    END;

-- 3. Credit Card Masking Policy (PCI)
-- Logic: Total obfuscation except for last 4 digits.
CREATE MASKING POLICY IF NOT EXISTS POL_MASK_PCI AS (val string) RETURNS string ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_STEWARD', 'ACCOUNTADMIN') THEN val
        ELSE 'XXXX-XXXX-XXXX-' || RIGHT(val, 4)
    END;

-- Note: Policies are applied dynamically in dbt via meta tags during Gold layer materialization.
