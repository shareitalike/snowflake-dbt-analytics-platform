-- ==============================================================================
-- 06_replay_tests.sql
-- Description: Unit tests for Replay and Recovery mechanisms
-- Phase: 08 - CDC Framework (Module 7)
-- ==============================================================================

USE ROLE DATA_ENGINEER;

-- ==========================================
-- TEST CASE 1: Failed Batch Replay
-- ==========================================
-- Setup: Create a failed batch in the metadata table.
INSERT INTO DB_PROD_METADATA.SC_META_CONTROL.TB_BATCH_CONTROL 
(Batch_ID, Pipeline_ID, Status, Low_Watermark) 
VALUES ('TEST_FAIL_001', 'PIPE_SHOPIFY_ORDERS', 'FAILED', '2026-07-01 00:00:00'::TIMESTAMP_LTZ);

-- Execute Replay
CALL DB_PROD_CURATED.SC_UTILITIES.SP_REPLAY_FAILED_BATCH('TEST_FAIL_001');

-- Validation 1: Status must be updated to REPLAYED
SELECT Status FROM DB_PROD_METADATA.SC_META_CONTROL.TB_BATCH_CONTROL WHERE Batch_ID = 'TEST_FAIL_001';
-- Validation 2: Audit log must contain the replay action
SELECT Action_Type, Details FROM DB_PROD_METADATA.SC_META_CONTROL.TB_RECOVERY_LOG WHERE Pipeline_ID = 'PIPE_SHOPIFY_ORDERS' AND Action_Type = 'REPLAY_EXECUTION';

-- ==========================================
-- TEST CASE 2: Duplicate Replay Prevention (Idempotency)
-- ==========================================
-- Re-execute the same replay. The SP should execute, but the underlying MERGE 
-- will report 0 rows updated because the target checksum matches perfectly.
CALL DB_PROD_CURATED.SC_UTILITIES.SP_REPLAY_FAILED_BATCH('TEST_FAIL_001');

-- ==========================================
-- TEST CASE 3: Recovery Validation (Stale Stream)
-- ==========================================
-- Execute the Stale Stream recovery procedure.
-- Ensure you have set the Watermark to a known timestamp first.
UPDATE DB_PROD_METADATA.SC_META_CONTROL.TB_WATERMARK 
SET High_Watermark = '2026-07-06 12:00:00'::TIMESTAMP_LTZ 
WHERE Pipeline_ID = 'PIPE_TEST_STREAM';

CALL DB_PROD_CURATED.SC_UTILITIES.SP_RECOVER_STALE_STREAM(
    'DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_TEST', 
    'DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_TEST', 
    'PIPE_TEST_STREAM'
);

-- Validation: The audit log should confirm the stream was recreated AT the watermark timestamp.
SELECT Details FROM DB_PROD_METADATA.SC_META_CONTROL.TB_RECOVERY_LOG WHERE Action_Type = 'STREAM_RECREATION' AND Pipeline_ID = 'PIPE_TEST_STREAM';
