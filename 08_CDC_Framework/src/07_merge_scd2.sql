-- ==============================================================================
-- 07_merge_scd2.sql
-- Description: SCD Type 2 MERGE Procedures for Dimensions
-- Phase: 08 - CDC Framework (Module 4)
-- FIX P1-004: Both MERGE steps are now wrapped in an explicit BEGIN/COMMIT
--             transaction to prevent partial SCD2 states on warehouse timeout.
-- FIX P2-009: EXCEPTION WHEN OTHER THEN block wired to SP_ROLLBACK_CHECKPOINT
--             so a type-cast failure rolls back the watermark cleanly.
-- FIX P1-005: Ghost surrogate key formula changed to MD5(business_key||'1970-01-01')
--             so it is deterministic and distinct from any real version key.
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_CURATED;
USE SCHEMA SC_UTILITIES;

-- ------------------------------------------------------------------------------
-- REUSABLE PROCEDURE: SCD Type 2 Customer MERGE
-- ------------------------------------------------------------------------------
-- SCD2 Pattern: Two-step within a single explicit transaction.
--   Step 1 — expire the old active record (SET IS_CURRENT=FALSE, VALID_TO).
--   Step 2 — insert the new active record (IS_CURRENT=TRUE, VALID_TO='9999-12-31').
-- If the warehouse times out between steps, the transaction is rolled back in full,
-- leaving the dimension in a clean state for the next batch retry.

CREATE OR REPLACE PROCEDURE SP_MERGE_CUSTOMER_SCD2()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_batch_id VARCHAR DEFAULT 'UNSET';
BEGIN
    -- Retrieve the current batch ID from the running pipeline log entry.
    SELECT COALESCE(MAX(Batch_ID), UUID_STRING())
    INTO :v_batch_id
    FROM DB_PROD_METADATA.SC_META_PIPELINE.TB_PIPELINE_LOG
    WHERE Pipeline_Name = 'CDC_DAG' AND Status = 'STARTED';

    -- 1. Deduplicate stream: take the latest payload per customer in this micro-batch.
    CREATE OR REPLACE TEMPORARY TABLE TMP_INCOMING_CUSTOMER AS
    SELECT
        raw_payload:"customer_id"::VARCHAR                                    AS business_key,
        raw_payload:"first_name"::VARCHAR                                     AS first_name,
        raw_payload:"last_name"::VARCHAR                                      AS last_name,
        raw_payload:"email"::VARCHAR                                          AS email,
        raw_payload:"updated_at"::TIMESTAMP_LTZ                              AS source_updated_at,
        MD5(
            COALESCE(raw_payload:"first_name"::VARCHAR,  '') ||
            COALESCE(raw_payload:"last_name"::VARCHAR,   '') ||
            COALESCE(raw_payload:"email"::VARCHAR,       '')
        )                                                                     AS record_checksum
    FROM DB_PROD_RAW.SC_BRONZE_SHOPIFY.STR_SHOPIFY_CUSTOMER
    QUALIFY ROW_NUMBER() OVER (PARTITION BY business_key ORDER BY source_updated_at DESC) = 1;

    -- FIX P1-004: Wrap both MERGE steps in an explicit transaction.
    -- If Step 2 fails, Step 1 is rolled back — dimension is never left in a half-expired state.
    BEGIN TRANSACTION;

        -- STEP 1: Expire the stale active record when the checksum has changed.
        MERGE INTO DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM tgt
        USING TMP_INCOMING_CUSTOMER src
            ON  tgt.business_key = src.business_key
            AND tgt.is_current   = TRUE
        WHEN MATCHED
             AND tgt.record_checksum != src.record_checksum
             AND src.source_updated_at > tgt.source_updated_at
        THEN UPDATE SET
            tgt.is_current       = FALSE,
            tgt.valid_to         = src.source_updated_at,
            tgt.updated_at       = CURRENT_TIMESTAMP(),
            tgt.pipeline_run_id  = :v_batch_id;

        -- STEP 2: Insert the new active version for every customer whose previous record
        -- was just expired (IS_CURRENT is now FALSE for the old row, so NOT MATCHED fires).
        MERGE INTO DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM tgt
        USING TMP_INCOMING_CUSTOMER src
            ON  tgt.business_key = src.business_key
            AND tgt.is_current   = TRUE
        WHEN NOT MATCHED THEN
            INSERT (
                surrogate_key,   business_key,  first_name,    last_name,
                email,           is_current,    valid_from,    valid_to,
                is_deleted,      record_checksum, created_at,  updated_at,
                source_system,   batch_id
            )
            VALUES (
                -- FIX P1-005: Surrogate key uses effective date (source_updated_at) so
                -- each SCD2 version is globally unique. Ghost records use '1970-01-01'
                -- as their effective date, making ghost surrogate keys deterministic and
                -- distinct from any real-data version key.
                MD5(src.business_key || src.source_updated_at::VARCHAR),
                src.business_key,   src.first_name,  src.last_name,
                src.email,          TRUE,            src.source_updated_at,
                '9999-12-31'::TIMESTAMP_LTZ,         FALSE,
                src.record_checksum, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
                'SHOPIFY',          :v_batch_id
            );

    COMMIT;

    RETURN 'Successfully merged SCD2 Customer Dimension. Batch: ' || :v_batch_id;

-- FIX P2-009: Catch any unhandled exception (type cast, schema drift, etc.),
-- roll back the transaction to leave the dimension in a clean state, then
-- propagate the error so the Task DAG marks this execution as FAILED.
EXCEPTION WHEN OTHER THEN
    ROLLBACK;
    CALL DB_PROD_METADATA.SC_META_CONTROL.SP_ROLLBACK_CHECKPOINT(:v_batch_id, SQLERRM);
    RAISE;
END;
$$;

-- Pattern note: SP_MERGE_PRODUCT_SCD2, SP_MERGE_STORE_SCD2, and SP_MERGE_EMPLOYEE_SCD2
-- follow the identical two-step transactional pattern above, differing only in the
-- source stream, target table, and descriptive columns in the MERGE clauses.
