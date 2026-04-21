/* ==============================================================================
 * FILE: 03_rollback_scripts.sql
 * PHASE: 08 - CDC Framework (Module 2)
 * 
 * EXPLANATION: Provides emergency drop and recreate scripts for CDC streams to handle schema evolution or base table recreation scenarios.
 * DESIGN DECISIONS: explicitly drops and recreates streams with APPEND_ONLY = TRUE. Documents the warning that this resets the stream offset to the current timestamp.
 * WHY: When a base table is replaced, attached streams immediately become stale. This script enables fast recovery but requires engineers to be aware of potential data loss (handled via High-Watermark Replay) since the offset resets.
 * ============================================================================== */

USE ROLE DATA_ENGINEER;

-- ROLLBACK SCENARIO: A base table was dropped or replaced (e.g., using CREATE OR REPLACE TABLE),
-- which causes all associated streams to go STALE immediately. 
-- The following script drops the stale stream and recreates it.
-- 
-- WARNING: Recreating a stream resets its offset to the current timestamp.
-- Any data in the base table that was not consumed prior to the drop will be missed 
-- by the new stream unless a time travel clone or high-watermark replay is utilized.

-- 1. Drop Stale Streams
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_CUSTOMER;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDER_ITEMS;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_PRODUCTS;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_POS.STR_POS_INVENTORY;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_POS.STR_POS_STORE;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_POS.STR_POS_RETURNS;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_STRIPE.STR_STRIPE_PAYMENTS;

-- 2. Recreate Streams
CREATE STREAM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_CUSTOMER 
    ON TABLE DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_CUSTOMER APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDER_ITEMS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDER_ITEMS APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_PRODUCTS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_PRODUCTS APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_POS.STR_POS_INVENTORY 
    ON TABLE DB_PROD_RAW.SC_BRONZE_POS.TB_RAW_POS_INVENTORY APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_POS.STR_POS_STORE 
    ON TABLE DB_PROD_RAW.SC_BRONZE_POS.TB_RAW_POS_STORE APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_POS.STR_POS_RETURNS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_POS.TB_RAW_POS_RETURNS APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_STRIPE.STR_STRIPE_PAYMENTS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_STRIPE.TB_RAW_STRIPE_PAYMENTS APPEND_ONLY = TRUE;

-- (Refer to Module 1 Architecture: High-Watermark Replay Strategy if data loss occurred).
