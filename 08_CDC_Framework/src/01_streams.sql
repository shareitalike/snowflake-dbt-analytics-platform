-- ==============================================================================
-- 01_streams.sql
-- Description: CDC Streams for Enterprise Bronze Tables
-- Phase: 08 - CDC Framework (Module 2)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_RAW;

-- ------------------------------------------------------------------------------
-- 1. SHOPIFY STREAMS (E-Commerce)
-- ------------------------------------------------------------------------------
USE SCHEMA SC_BRONZE_SHOPIFY;

-- Customer (Append-Only)
-- Reason: Data is ingested via Snowpipe which only performs INSERTs. 
-- Using APPEND_ONLY=TRUE reduces Snowflake metadata tracking overhead.
CREATE STREAM IF NOT EXISTS STR_SHOPIFY_CUSTOMER 
    ON TABLE TB_RAW_SHOPIFY_CUSTOMER
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for raw Shopify customer payloads';

-- Orders (Append-Only)
CREATE STREAM IF NOT EXISTS STR_SHOPIFY_ORDERS 
    ON TABLE TB_RAW_SHOPIFY_ORDERS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for raw Shopify order payloads';

-- Order Items (Append-Only)
CREATE STREAM IF NOT EXISTS STR_SHOPIFY_ORDER_ITEMS 
    ON TABLE TB_RAW_SHOPIFY_ORDER_ITEMS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for raw Shopify order line items';

-- Products (Append-Only)
CREATE STREAM IF NOT EXISTS STR_SHOPIFY_PRODUCTS 
    ON TABLE TB_RAW_SHOPIFY_PRODUCTS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for raw Shopify product catalog';

-- ------------------------------------------------------------------------------
-- 2. POS STREAMS (Store Operations)
-- ------------------------------------------------------------------------------
USE SCHEMA SC_BRONZE_POS;

-- Inventory (Append-Only)
CREATE STREAM IF NOT EXISTS STR_POS_INVENTORY 
    ON TABLE TB_RAW_POS_INVENTORY
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for real-time store inventory ticks';

-- Store (Append-Only)
CREATE STREAM IF NOT EXISTS STR_POS_STORE 
    ON TABLE TB_RAW_POS_STORE
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for physical store hierarchy data';

-- Returns (Append-Only)
CREATE STREAM IF NOT EXISTS STR_POS_RETURNS 
    ON TABLE TB_RAW_POS_RETURNS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for POS return transactions';

-- ------------------------------------------------------------------------------
-- 3. STRIPE STREAMS (Finance)
-- ------------------------------------------------------------------------------
USE SCHEMA SC_BRONZE_STRIPE;

-- Payments (Append-Only)
CREATE STREAM IF NOT EXISTS STR_STRIPE_PAYMENTS 
    ON TABLE TB_RAW_STRIPE_PAYMENTS
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for Stripe payment intents and captures';

-- ------------------------------------------------------------------------------
-- 4. SALESFORCE STREAMS (CRM & Marketing)
-- ------------------------------------------------------------------------------
USE SCHEMA SC_BRONZE_SALESFORCE;

-- Promotion (Append-Only)
CREATE STREAM IF NOT EXISTS STR_SF_PROMOTION 
    ON TABLE TB_RAW_SF_PROMOTION
    APPEND_ONLY = TRUE
    COMMENT = 'CDC stream for Salesforce marketing promotions';

-- ------------------------------------------------------------------------------
-- 5. ORACLE ERP STREAMS (Enterprise Resource Planning)
-- ------------------------------------------------------------------------------
USE SCHEMA SC_BRONZE_ORACLE_ERP;

-- Supplier (Standard Stream)
-- Reason: Oracle ERP syncs might use an external tool (like Fivetran/Matillion) 
-- that performs direct UPDATE/DELETE on the raw table. Therefore, we use a Standard Stream.
CREATE STREAM IF NOT EXISTS STR_ORACLE_SUPPLIER 
    ON TABLE TB_RAW_ORACLE_SUPPLIER
    COMMENT = 'Standard CDC stream tracking inserts, updates, and deletes for Suppliers';

-- Employee (Standard Stream)
CREATE STREAM IF NOT EXISTS STR_ORACLE_EMPLOYEE 
    ON TABLE TB_RAW_ORACLE_EMPLOYEE
    COMMENT = 'Standard CDC stream tracking inserts, updates, and deletes for HR Employees';

-- ------------------------------------------------------------------------------
-- 6. REFERENCE DATA STREAMS
-- ------------------------------------------------------------------------------
USE DATABASE DB_PROD_REFERENCE;
USE SCHEMA SC_GLOBAL;

-- Reference Data (Standard Stream)
-- Reason: Reference tables (like Currency Conversions, ISO mappings) are manually 
-- managed via DML (INSERT/UPDATE/DELETE). We need to capture all changes.
CREATE STREAM IF NOT EXISTS STR_GLOBAL_CURRENCY 
    ON TABLE TB_REF_CURRENCY
    COMMENT = 'Standard CDC stream tracking all changes to reference data';
