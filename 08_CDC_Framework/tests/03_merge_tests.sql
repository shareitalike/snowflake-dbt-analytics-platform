-- ==============================================================================
-- 03_merge_tests.sql
-- Description: Test Cases for Idempotent MERGE logic
-- Phase: 08 - CDC Framework (Module 4)
-- ==============================================================================

USE ROLE DATA_ENGINEER;

-- ==========================================
-- TEST CASE 1: Late Arriving Record Handling
-- ==========================================
-- 1. Insert a newer record into the Stream manually.
-- 2. Execute the MERGE procedure.
-- 3. Insert an OLDER record for the exact same business_key into the Stream.
-- 4. Execute the MERGE procedure.
-- Validation: The older record MUST be ignored because `src.source_updated_at > tgt.source_updated_at` evaluates to FALSE.

-- ==========================================
-- TEST CASE 2: Idempotent Execution (Duplicate Run)
-- ==========================================
-- 1. Suspend the Stream offset advance mechanism (e.g. run MERGE without COMMIT, or re-insert the payload).
-- 2. Run the MERGE twice.
-- Validation: Because the `record_checksum` did not change, the second MERGE run results in 0 rows updated/inserted.

-- ==========================================
-- TEST CASE 3: SCD2 Versioning
-- ==========================================
-- 1. Update the email address of an existing customer in the source payload.
-- 2. Execute the MERGE procedure.
-- Validation: 
-- - The old record's `is_current` is FALSE, and `valid_to` is populated.
-- - The new record's `is_current` is TRUE, and `valid_to` is '9999-12-31'.
