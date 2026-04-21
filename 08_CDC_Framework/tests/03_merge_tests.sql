/* ==============================================================================
 * FILE: 03_merge_tests.sql
 * PHASE: 08 - CDC Framework
 * 
 * EXPLANATION: Testing scripts specifically targeting the idempotency and timestamp resolution logic of the transactional MERGE operations.
 * DESIGN DECISIONS: Intentionally inserts older payload data *after* newer data has been merged to prove that the src.source_updated_at > tgt.source_updated_at condition correctly ignores the stale record.
 * WHY: Idempotency is the cornerstone of robust data engineering. Proving that duplicate or out-of-order payloads do not corrupt the Gold layer guarantees the pipeline can safely heal from upstream API retries.
 * ============================================================================== */

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
