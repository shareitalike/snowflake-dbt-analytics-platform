/* ==============================================================================
 * FILE: 02_schemas.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Sets up domain-driven schemas within the provisioned databases to organize tables logically by business unit and pipeline stage.
 * DESIGN DECISIONS: Separates raw data by source system (e.g., SC_BRONZE_SHOPIFY), silver data by business domain (e.g., SC_SILVER_SALES), and gold data by consumption audience (e.g., SC_GOLD_EXECUTIVE).
 * WHY: Strict schema segregation allows fine-grained RBAC grants (e.g., granting Marketing access only to SC_GOLD_MARKETING) and prevents name collisions across complex enterprise domains.
 * ============================================================================== */

USE ROLE SYSADMIN;

-- ------------------------------------------------------------------------------
-- DB_PROD_RAW (BRONZE)
-- ------------------------------------------------------------------------------
USE DATABASE DB_PROD_RAW;
CREATE SCHEMA IF NOT EXISTS SC_BRONZE_SHOPIFY;
CREATE SCHEMA IF NOT EXISTS SC_BRONZE_STRIPE;
CREATE SCHEMA IF NOT EXISTS SC_BRONZE_POS;
CREATE SCHEMA IF NOT EXISTS SC_BRONZE_SALESFORCE;
CREATE SCHEMA IF NOT EXISTS SC_BRONZE_ORACLE_ERP;

-- ------------------------------------------------------------------------------
-- DB_PROD_CURATED (SILVER)
-- ------------------------------------------------------------------------------
USE DATABASE DB_PROD_CURATED;
CREATE SCHEMA IF NOT EXISTS SC_SILVER_SALES;
CREATE SCHEMA IF NOT EXISTS SC_SILVER_CUSTOMER;
CREATE SCHEMA IF NOT EXISTS SC_SILVER_FINANCE;
CREATE SCHEMA IF NOT EXISTS SC_SILVER_INVENTORY;

-- ------------------------------------------------------------------------------
-- DB_PROD_ANALYTICS (GOLD)
-- ------------------------------------------------------------------------------
USE DATABASE DB_PROD_ANALYTICS;
CREATE SCHEMA IF NOT EXISTS SC_GOLD_CORE;      -- Kimball Dimensions and Facts
CREATE SCHEMA IF NOT EXISTS SC_GOLD_EXECUTIVE; -- Secure Views for Exec Dashboards
CREATE SCHEMA IF NOT EXISTS SC_GOLD_MARKETING; -- Secure Views for Marketing

-- ------------------------------------------------------------------------------
-- DB_PROD_METADATA
-- ------------------------------------------------------------------------------
USE DATABASE DB_PROD_METADATA;
CREATE SCHEMA IF NOT EXISTS SC_META_DBT;       -- dbt execution artifacts
CREATE SCHEMA IF NOT EXISTS SC_META_AIRFLOW;   -- Airflow execution logs
CREATE SCHEMA IF NOT EXISTS SC_META_PIPELINE;  -- Custom CDC tracking metrics

-- ------------------------------------------------------------------------------
-- DB_PROD_GOVERNANCE
-- ------------------------------------------------------------------------------
USE DATABASE DB_PROD_GOVERNANCE;
CREATE SCHEMA IF NOT EXISTS SC_GOV_POLICIES;   -- DDM and RAP logic
CREATE SCHEMA IF NOT EXISTS SC_GOV_TAGS;       -- Cost and Data Classification tags
CREATE SCHEMA IF NOT EXISTS SC_GOV_MAPPINGS;   -- Entitlement mapping tables
