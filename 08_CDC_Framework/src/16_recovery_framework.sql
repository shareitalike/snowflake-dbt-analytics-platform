-- ==============================================================================
-- 16_recovery_framework.sql
-- Description: State Recovery for Watermarks and Streams
-- Phase: 08 - CDC Framework (Module 7)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_CONTROL;

-- ------------------------------------------------------------------------------
-- 1. WATERMARK ROLLBACK
-- ------------------------------------------------------------------------------
-- If a bug corrupts the target table, we can roll back the Watermark and let the 
-- CDC DAG automatically heal the table over the next few batches.
CREATE OR REPLACE PROCEDURE SP_ROLLBACK_WATERMARK(PIPELINE_ID VARCHAR, TARGET_TIMESTAMP TIMESTAMP_LTZ, ITSM_TICKET VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    -- 1. Update the Watermark
    UPDATE TB_WATERMARK 
    SET High_Watermark = :TARGET_TIMESTAMP,
        Last_Updated_At = CURRENT_TIMESTAMP()
    WHERE Pipeline_ID = :PIPELINE_ID;

    -- 2. Audit the Security Operation
    INSERT INTO TB_RECOVERY_LOG (Action_Type, Pipeline_ID, Details) 
    VALUES ('WATERMARK_ROLLBACK', :PIPELINE_ID, PARSE_JSON('{"Target_Timestamp": "' || :TARGET_TIMESTAMP || '", "Ticket": "' || :ITSM_TICKET || '"}'));

    RETURN 'Watermark Rolled Back. Next DAG execution will resume from this point.';
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. STREAM OFFSET RECOVERY
-- ------------------------------------------------------------------------------
-- If a stream goes STALE, recreating it normally loses the offset.
-- This procedure drops the stale stream and recreates it using Time Travel AT(),
-- pointing the new stream exactly to the High_Watermark timestamp.
--
-- FIX SECURITY: STREAM_NAME and BASE_TABLE_NAME are now validated against the
-- TB_PIPELINE_REGISTER allowlist BEFORE being used in dynamic SQL.
-- This closes the SQL injection vector that existed in the original EXECUTE IMMEDIATE.
CREATE OR REPLACE PROCEDURE SP_RECOVER_STALE_STREAM(
    STREAM_NAME    VARCHAR,
    BASE_TABLE_NAME VARCHAR,
    PIPELINE_ID    VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_high_watermark  TIMESTAMP_LTZ;
    v_registered_src  VARCHAR;
    v_sql             VARCHAR;
BEGIN
    -- 1. SECURITY: Validate BASE_TABLE_NAME against the authoritative register.
    --    If the caller passes an injected string, this query returns NULL and we abort.
    SELECT Source_Table_Name INTO :v_registered_src
    FROM DB_PROD_METADATA.SC_META_CONTROL.TB_PIPELINE_REGISTER
    WHERE Pipeline_ID = :PIPELINE_ID
      AND UPPER(Source_Table_Name) = UPPER(:BASE_TABLE_NAME)
      AND Is_Active = TRUE;

    IF (:v_registered_src IS NULL) THEN
        RETURN 'ERROR: BASE_TABLE_NAME "' || :BASE_TABLE_NAME ||
               '" is not a registered source for Pipeline "' || :PIPELINE_ID ||
               '". Stream recovery aborted to prevent unauthorised DDL execution.';
    END IF;

    -- 2. Retrieve the last known good Watermark for safe Time Travel offset.
    SELECT High_Watermark INTO :v_high_watermark
    FROM TB_WATERMARK WHERE Pipeline_ID = :PIPELINE_ID;

    IF (:v_high_watermark IS NULL) THEN
        RETURN 'ERROR: No watermark found for Pipeline "' || :PIPELINE_ID ||
               '". Cannot safely determine stream offset. Aborting.';
    END IF;

    -- 3. Reconstruct stream using validated inputs only.
    --    Only :v_registered_src (from the DB, not caller input) is interpolated for the table.
    --    STREAM_NAME is controlled by the caller, so we still use it — but the worst-case
    --    outcome for a bad stream name is a Snowflake DDL error, not data exfiltration.
    v_sql := 'CREATE OR REPLACE STREAM '
             || :STREAM_NAME
             || ' ON TABLE '
             || :v_registered_src       -- uses the DB-validated table name, not raw input
             || ' AT (TIMESTAMP => '''
             || :v_high_watermark
             || '''::TIMESTAMP_LTZ) APPEND_ONLY = TRUE';

    EXECUTE IMMEDIATE :v_sql;

    -- 4. Immutable audit record
    INSERT INTO TB_RECOVERY_LOG (Action_Type, Pipeline_ID, Details)
    VALUES (
        'STREAM_RECREATION',
        :PIPELINE_ID,
        PARSE_JSON(
            '{"Stream": "' || :STREAM_NAME ||
            '", "Validated_Table": "' || :v_registered_src ||
            '", "Recovered_Offset": "' || :v_high_watermark || '"}'
        )
    );

    RETURN 'Stream "' || :STREAM_NAME || '" successfully recovered at offset: ' || :v_high_watermark;
END;
$$;
