/* ==============================================================================
 * FILE: recovery_procedures.sql
 * PHASE: 12 - Platform Engineering
 * 
 * EXPLANATION: Outlines the exact SQL commands required for disaster recovery scenarios, including accidental table drops, bad data merges, and Zero-Copy Cloning for QA.
 * DESIGN DECISIONS: Leverages Snowflake's native Time Travel (AT(TIMESTAMP => ...)) to instantly clone historical table states for recovery, bypassing traditional, hours-long restore-from-backup processes.
 * WHY: Documenting these precise commands reduces MTTR (Mean Time To Recovery) from hours to seconds during a live production incident. Zero-Copy clones drastically reduce storage costs for QA/UAT environments since they only charge for copy-on-write deltas.
 * ============================================================================== */

USE ROLE SYSADMIN;

-- ==============================================================================
-- SCENARIO 1: Accidental Table Drop
-- A developer accidentally ran DROP TABLE on FCT_SALES in production.
-- Recovery Time: < 30 seconds
-- ==============================================================================

-- Step 1: UNDROP the table (available within the Time Travel retention window)
UNDROP TABLE OMNIRETAIL.GOLD.FCT_SALES;

-- Verification: Confirm data is intact
SELECT COUNT(*) AS recovered_rows FROM OMNIRETAIL.GOLD.FCT_SALES;

-- ==============================================================================
-- SCENARIO 2: Corrupted Data (Bad MERGE overwrote valid records)
-- A faulty CDC MERGE corrupted 50,000 rows in DIM_CUSTOMER at 10:15 AM.
-- We need to restore the table to its state at 10:00 AM (before the MERGE).
-- Recovery Time: < 2 minutes
-- ==============================================================================

-- Step 1: Query the table AS OF the timestamp before corruption
SELECT * FROM OMNIRETAIL.GOLD.DIM_CUSTOMER
AT (TIMESTAMP => '2025-07-07 10:00:00'::TIMESTAMP_LTZ)
LIMIT 10; -- Verify this is the correct state

-- Step 2: Create a recovery clone from the historical state
CREATE OR REPLACE TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER_RECOVERED
CLONE OMNIRETAIL.GOLD.DIM_CUSTOMER
AT (TIMESTAMP => '2025-07-07 10:00:00'::TIMESTAMP_LTZ);

-- Step 3: Swap the recovered table into production (atomic operation)
ALTER TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER RENAME TO OMNIRETAIL.GOLD.DIM_CUSTOMER_CORRUPTED;
ALTER TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER_RECOVERED RENAME TO OMNIRETAIL.GOLD.DIM_CUSTOMER;

-- Step 4: Cleanup after validation
-- DROP TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER_CORRUPTED;

-- ==============================================================================
-- SCENARIO 3: Zero-Copy Clone for QA / UAT Environment
-- The QA team needs a full copy of production Gold data for testing.
-- Traditional approach: CTAS = hours + doubles storage cost.
-- Zero-Copy Clone: Instantaneous + zero additional storage.
-- ==============================================================================

CREATE DATABASE OMNIRETAIL_QA CLONE OMNIRETAIL;
-- This clones the ENTIRE database (all schemas, tables, views) in seconds.
-- Storage cost = $0 until QA modifies data (copy-on-write).

-- ==============================================================================
-- SCENARIO 4: Cross-Region Replication Architecture (Disaster Recovery)
-- If the primary us-east-1 region goes down, we failover to us-west-2.
-- This is ARCHITECTURAL DOCUMENTATION — requires Snowflake Enterprise Edition.
-- ==============================================================================

-- Step 1: Create a Failover Group on the PRIMARY account
-- ALTER DATABASE OMNIRETAIL ENABLE REPLICATION TO ACCOUNTS omniretail_dr.us-west-2;
-- CREATE FAILOVER GROUP PROD_FAILOVER_GROUP
--   OBJECT_TYPES = DATABASES, ROLES, WAREHOUSES
--   ALLOWED_DATABASES = OMNIRETAIL
--   ALLOWED_ACCOUNTS = omniretail_dr.us-west-2
--   REPLICATION_SCHEDULE = '10 MINUTES';

-- Step 2: On the SECONDARY account (us-west-2), promote to primary during outage
-- ALTER FAILOVER GROUP PROD_FAILOVER_GROUP PRIMARY;

-- RTO: ~10 minutes (replication lag + DNS cutover)
-- RPO: ~10 minutes (last successful replication)
