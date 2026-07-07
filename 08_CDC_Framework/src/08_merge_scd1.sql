-- ==============================================================================
-- 08_merge_scd1.sql
-- Description: SCD Type 1 (Overwrite) MERGE Procedures for Reference Data
-- Phase: 08 - CDC Framework (Module 4)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_CURATED;
USE SCHEMA SC_UTILITIES;

-- ------------------------------------------------------------------------------
-- REUSABLE PROCEDURE: SCD Type 1 Currency MERGE
-- ------------------------------------------------------------------------------
-- SCD1 does not track history. It overwrites the existing row with the newest data.

CREATE OR REPLACE PROCEDURE SP_MERGE_CURRENCY_SCD1()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    MERGE INTO DB_PROD_REFERENCE.SC_GLOBAL.TB_REF_CURRENCY tgt
    USING (
        SELECT 
            currency_code,
            conversion_rate,
            METADATA$ACTION,
            METADATA$ISUPDATE,
            CURRENT_TIMESTAMP() as updated_at
        FROM DB_PROD_REFERENCE.SC_GLOBAL.STR_GLOBAL_CURRENCY
        -- Handle multiple changes in the same micro-batch by taking the latest
        QUALIFY ROW_NUMBER() OVER (PARTITION BY currency_code ORDER BY updated_at DESC) = 1
    ) src
    ON tgt.currency_code = src.currency_code
    
    -- Handle Soft Deletes from Standard Stream
    WHEN MATCHED AND src.METADATA$ACTION = 'DELETE' THEN
        UPDATE SET tgt.is_deleted = TRUE, tgt.updated_at = CURRENT_TIMESTAMP()
        
    -- Handle Updates
    WHEN MATCHED AND src.METADATA$ACTION = 'INSERT' AND src.METADATA$ISUPDATE = TRUE THEN
        UPDATE SET 
            tgt.conversion_rate = src.conversion_rate,
            tgt.updated_at = CURRENT_TIMESTAMP()
            
    -- Handle New Inserts
    WHEN NOT MATCHED AND src.METADATA$ACTION = 'INSERT' THEN
        INSERT (currency_code, conversion_rate, created_at, updated_at, is_deleted)
        VALUES (src.currency_code, src.conversion_rate, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), FALSE);

    RETURN 'Successfully merged SCD1 Currency Reference Data';
END;
$$;
