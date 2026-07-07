-- ==============================================================================
-- 04_watermark_tests.sql
-- Description: Unit tests for Watermark and Checkpoint Framework
-- Phase: 08 - CDC Framework (Module 5)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_CONTROL;

-- ==========================================
-- TEST SETUP
-- ==========================================
INSERT INTO TB_PIPELINE_REGISTER (Pipeline_ID, Target_Table_Name, Source_Table_Name)
VALUES ('TEST_PIPE_001', 'TB_SILVER_TEST', 'TB_BRONZE_TEST');

-- ==========================================
-- TEST CASE 1: First Load (Missing Watermark)
-- ==========================================
-- Simulates the very first execution where no high watermark exists.
CALL SP_CREATE_CHECKPOINT('TEST_PIPE_001', 'RUN_001');

-- Validation: The returned Batch ID should create a record in TB_BATCH_CONTROL
-- with a Low_Watermark of '1970-01-01 00:00:00'.
SELECT Low_Watermark, Status FROM TB_BATCH_CONTROL WHERE Pipeline_ID = 'TEST_PIPE_001' AND Status = 'STARTED';

-- ==========================================
-- TEST CASE 2: Successful Commit (Watermark Update)
-- ==========================================
-- Simulates a successful batch processing up to '2025-01-01 12:00:00'.
SET current_batch_id = (SELECT MAX(Batch_ID) FROM TB_BATCH_CONTROL WHERE Pipeline_ID = 'TEST_PIPE_001');
CALL SP_UPDATE_CHECKPOINT($current_batch_id, '2025-01-01 12:00:00'::TIMESTAMP_LTZ, 100, 50);

-- Validation: TB_WATERMARK should now hold '2025-01-01 12:00:00'.
SELECT High_Watermark FROM TB_WATERMARK WHERE Pipeline_ID = 'TEST_PIPE_001';

-- ==========================================
-- TEST CASE 3: Incremental Load
-- ==========================================
CALL SP_CREATE_CHECKPOINT('TEST_PIPE_001', 'RUN_002');

-- Validation: The new Low_Watermark should exactly equal the previous High_Watermark ('2025-01-01 12:00:00').
SELECT Low_Watermark FROM TB_BATCH_CONTROL WHERE Pipeline_ID = 'TEST_PIPE_001' AND Status = 'STARTED';

-- ==========================================
-- TEST CASE 4: Failed Load (Rollback)
-- ==========================================
SET fail_batch_id = (SELECT MAX(Batch_ID) FROM TB_BATCH_CONTROL WHERE Pipeline_ID = 'TEST_PIPE_001' AND Status = 'STARTED');
CALL SP_ROLLBACK_CHECKPOINT($fail_batch_id, 'Simulated Warehouse Timeout');

-- Validation: 
-- 1. Batch status should be FAILED.
-- 2. TB_WATERMARK should STILL be '2025-01-01 12:00:00' (it did not advance).
SELECT Status, Error_Message FROM TB_BATCH_CONTROL WHERE Batch_ID = $fail_batch_id;
SELECT High_Watermark FROM TB_WATERMARK WHERE Pipeline_ID = 'TEST_PIPE_001';

-- ==========================================
-- TEST CASE 5: Restart (Duplicate Batch Prevention)
-- ==========================================
-- Because the previous batch failed, the Watermark did not advance. 
-- The next call to SP_CREATE_CHECKPOINT will generate a NEW Batch_ID but retrieve 
-- the exact same Low_Watermark as the failed batch, ensuring the exact same data slice is re-processed safely.
CALL SP_CREATE_CHECKPOINT('TEST_PIPE_001', 'RUN_003');
SELECT Low_Watermark FROM TB_BATCH_CONTROL WHERE Pipeline_ID = 'TEST_PIPE_001' AND Status = 'STARTED';
