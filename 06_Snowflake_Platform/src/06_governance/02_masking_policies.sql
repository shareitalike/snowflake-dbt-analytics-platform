-- ==============================================================================
-- 02_masking_policies.sql
-- Description: Dynamic Data Masking (DDM) for PII/PCI Compliance
-- ==============================================================================

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
