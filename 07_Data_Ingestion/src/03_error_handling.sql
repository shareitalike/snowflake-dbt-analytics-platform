-- ==============================================================================
-- 03_error_handling.sql
-- Description: Automated Replay & Dead Letter Queue (DLQ) Routing
-- Phase: 07 - Data Ingestion
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_RAW;
USE SCHEMA SC_BRONZE_QUARANTINE;

-- 1. Create Stored Procedure to Replay Failed Files
-- This procedure parses the COPY_HISTORY, finds files that failed to load
-- (where status = 'FAILED' or errors_seen > 0), and attempts to re-ingest them manually.

CREATE OR REPLACE PROCEDURE SP_REPLAY_FAILED_FILES(PIPE_NAME VARCHAR, TARGET_TABLE VARCHAR)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
    var result = "Success";
    
    // 1. Identify failed files from the last 24 hours
    var sql_failed_files = `
        SELECT FILE_NAME 
        FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(TABLE_NAME=>'${TARGET_TABLE}', START_TIME=> DATEADD(hours, -24, CURRENT_TIMESTAMP())))
        WHERE STATUS = 'LOAD_FAILED' OR ERRORS_SEEN > 0
    `;
    
    var stmt = snowflake.createStatement({sqlText: sql_failed_files});
    var res = stmt.execute();
    
    // 2. Iterate and re-run COPY INTO explicitly for those files
    while (res.next()) {
        var failed_file = res.getColumnValue(1);
        
        try {
            // Re-run COPY INTO overriding the deduplication cache (FORCE=TRUE)
            var sql_replay = `
                COPY INTO ${TARGET_TABLE} 
                FROM @DB_PROD_RAW.SC_BRONZE_SHOPIFY.STG_AWS_S3_SHOPIFY
                FILES = ('${failed_file}')
                FORCE = TRUE
                ON_ERROR = CONTINUE
            `;
            snowflake.createStatement({sqlText: sql_replay}).execute();
        } catch (err) {
            // If it fails again, log it to the DLQ table
            var sql_dlq = `
                INSERT INTO DB_PROD_RAW.SC_BRONZE_QUARANTINE.TB_DLQ_PAYLOADS 
                (Source_System, Raw_Payload, Validation_Error)
                VALUES ('${PIPE_NAME}', PARSE_JSON('{"file": "${failed_file}"}'), 'REPLAY_FAILED: ${err.message}')
            `;
            snowflake.createStatement({sqlText: sql_dlq}).execute();
        }
    }
    
    return "Processed re-ingestion for " + PIPE_NAME;
$$;

-- Note: This stored procedure can be scheduled via a Snowflake TASK or triggered by Airflow.
