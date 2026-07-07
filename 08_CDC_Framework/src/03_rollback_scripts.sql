-- ==============================================================================
-- 03_rollback_scripts.sql
-- Description: Drop/Recreate scripts for CDC stream schema evolution
-- Phase: 08 - CDC Framework (Module 2)
-- ==============================================================================

USE ROLE DATA_ENGINEER;

-- ROLLBACK SCENARIO: A base table was dropped or replaced (e.g., using CREATE OR REPLACE TABLE),
-- which causes all associated streams to go STALE immediately. 
-- The following script drops the stale stream and recreates it.
-- 
-- WARNING: Recreating a stream resets its offset to the current timestamp.
-- Any data in the base table that was not consumed prior to the drop will be missed 
-- by the new stream unless a time travel clone or high-watermark replay is utilized.

-- 1. Drop Stale Streams
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS;
DROP STREAM IF EXISTS DB_PROD_RAW.SC_BRONZE_STRIPE.STR_STRIPE_PAYMENTS;

-- 2. Recreate Streams
CREATE STREAM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_ORDERS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS APPEND_ONLY = TRUE;

CREATE STREAM DB_PROD_RAW.SC_BRONZE_STRIPE.STR_STRIPE_PAYMENTS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_STRIPE.TB_RAW_STRIPE_PAYMENTS APPEND_ONLY = TRUE;

-- (Refer to Module 1 Architecture: High-Watermark Replay Strategy if data loss occurred).
