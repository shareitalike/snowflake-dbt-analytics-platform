-- ==============================================================================
-- 12_watermark_procedures.sql
-- Description: Reusable Checkpoint and Watermark Stored Procedures
-- Phase: 08 - CDC Framework (Module 5)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_CONTROL;

-- ------------------------------------------------------------------------------
-- 1. CREATE CHECKPOINT (START BATCH)
-- ------------------------------------------------------------------------------
-- Reads the previous High Watermark and creates a new STARTED batch record.
CREATE OR REPLACE PROCEDURE SP_CREATE_CHECKPOINT(PIPELINE_ID VARCHAR, PIPELINE_RUN_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_low_watermark TIMESTAMP_LTZ;
    v_batch_id VARCHAR;
BEGIN
    -- 1. Determine the Low Watermark (from the previous successful High Watermark)
    -- If no watermark exists (Initial Load), use a default old date.
    SELECT NVL(MAX(High_Watermark), '1970-01-01 00:00:00'::TIMESTAMP_LTZ) 
    INTO :v_low_watermark
    FROM TB_WATERMARK 
    WHERE Pipeline_ID = :PIPELINE_ID;

    -- 2. Generate a new Batch ID
    v_batch_id := UUID_STRING();

    -- 3. Insert the Checkpoint
    INSERT INTO TB_BATCH_CONTROL (
        Batch_ID, Pipeline_ID, Pipeline_Run_ID, Status, Low_Watermark
    ) VALUES (
        :v_batch_id, :PIPELINE_ID, :PIPELINE_RUN_ID, 'STARTED', :v_low_watermark
    );

    -- Return the Batch ID so the calling task can use it
    RETURN :v_batch_id;
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. UPDATE CHECKPOINT (COMMIT BATCH)
-- ------------------------------------------------------------------------------
-- Updates the batch status to COMPLETED and officially advances the Global Watermark.
CREATE OR REPLACE PROCEDURE SP_UPDATE_CHECKPOINT(
    BATCH_ID VARCHAR, 
    NEW_HIGH_WATERMARK TIMESTAMP_LTZ,
    ROWS_INS NUMBER, 
    ROWS_UPD NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_pipeline_id VARCHAR;
BEGIN
    -- 1. Retrieve Pipeline ID from the Batch
    SELECT Pipeline_ID INTO :v_pipeline_id 
    FROM TB_BATCH_CONTROL WHERE Batch_ID = :BATCH_ID;

    -- 2. Mark Batch as Completed
    UPDATE TB_BATCH_CONTROL
    SET Status = 'COMPLETED',
        High_Watermark = :NEW_HIGH_WATERMARK,
        Rows_Inserted = :ROWS_INS,
        Rows_Updated = :ROWS_UPD,
        Execution_End_Time = CURRENT_TIMESTAMP()
    WHERE Batch_ID = :BATCH_ID;

    -- 3. Advance the Global Watermark (Upsert)
    MERGE INTO TB_WATERMARK tgt
    USING (SELECT :v_pipeline_id as p_id, :NEW_HIGH_WATERMARK as hw, :BATCH_ID as b_id) src
    ON tgt.Pipeline_ID = src.p_id
    WHEN MATCHED THEN 
        UPDATE SET tgt.High_Watermark = src.hw, tgt.Last_Updated_At = CURRENT_TIMESTAMP(), tgt.Updated_By_Batch_ID = src.b_id
    WHEN NOT MATCHED THEN 
        INSERT (Pipeline_ID, High_Watermark, Updated_By_Batch_ID) VALUES (src.p_id, src.hw, src.b_id);

    RETURN 'Checkpoint Successfully Committed';
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. ROLLBACK CHECKPOINT (FAIL BATCH)
-- ------------------------------------------------------------------------------
-- Marks a batch as FAILED and captures the error. Does NOT advance the Watermark.
CREATE OR REPLACE PROCEDURE SP_ROLLBACK_CHECKPOINT(BATCH_ID VARCHAR, ERROR_MSG VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    UPDATE TB_BATCH_CONTROL
    SET Status = 'FAILED',
        Error_Message = :ERROR_MSG,
        Execution_End_Time = CURRENT_TIMESTAMP()
    WHERE Batch_ID = :BATCH_ID;

    RETURN 'Checkpoint Rolled Back';
END;
$$;
