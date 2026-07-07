-- ==============================================================================
-- 01_databases.sql
-- Description: Enterprise Logical Database Provisioning
-- ==============================================================================

USE ROLE SYSADMIN;

-- 1. RAW Database (Bronze Layer)
-- Holds immutable, untransformed JSON/CSV data. 1-day retention minimizes cost.
CREATE DATABASE IF NOT EXISTS DB_PROD_RAW 
    DATA_RETENTION_TIME_IN_DAYS = 1
    COMMENT = 'Immutable landing zone for raw source data (Bronze)';

-- 2. CURATED Database (Silver Layer)
-- Holds deduplicated, standardized entities. Fully reproducible via dbt.
CREATE DATABASE IF NOT EXISTS DB_PROD_CURATED
    DATA_RETENTION_TIME_IN_DAYS = 1
    COMMENT = 'Standardized, conformed entities (Silver)';

-- 3. ANALYTICS Database (Gold Layer)
-- Holds Kimball Star Schemas. 90-day retention for executive point-in-time recovery.
CREATE DATABASE IF NOT EXISTS DB_PROD_ANALYTICS
    DATA_RETENTION_TIME_IN_DAYS = 90
    COMMENT = 'Dimensional Data Marts and Semantic Layer (Gold)';

-- 4. GOVERNANCE Database
-- Stores masking policies, tags, and row access mapping tables.
CREATE DATABASE IF NOT EXISTS DB_PROD_GOVERNANCE
    DATA_RETENTION_TIME_IN_DAYS = 30
    COMMENT = 'Centralized governance policies and security mappings';

-- 5. METADATA Database
-- Stores platform operational metrics and dbt artifacts.
CREATE DATABASE IF NOT EXISTS DB_PROD_METADATA
    DATA_RETENTION_TIME_IN_DAYS = 30
    COMMENT = 'Platform operational metadata and dbt artifacts';

-- 6. REFERENCE Database
-- Static lookups (e.g., ISO codes, calendar tables).
CREATE DATABASE IF NOT EXISTS DB_PROD_REFERENCE
    DATA_RETENTION_TIME_IN_DAYS = 1
    COMMENT = 'Static enterprise reference data';

-- 7. SANDBOX Database
-- Ephemeral exploration zones.
CREATE DATABASE IF NOT EXISTS DB_PROD_SANDBOX
    DATA_RETENTION_TIME_IN_DAYS = 0
    COMMENT = 'Ephemeral data science and analyst sandbox';
