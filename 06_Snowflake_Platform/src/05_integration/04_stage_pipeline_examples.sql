/* ==============================================================================
 * FILE: 04_stage_pipeline_examples.sql
 * PHASE: 06 - Snowflake Platform / Storage Integration
 * 
 * EXPLANATION: This file provides annotated pipeline design examples for all 
 *              four types of Snowflake Stages (External, Named Internal, Table, and User).
 *              This serves as an official reference playbook for the Data Engineering team.
 * ============================================================================== */

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_RAW;
USE SCHEMA SC_BRONZE_SHOPIFY;

-- ==============================================================================
-- 1. EXTERNAL STAGE PIPELINE (The Bronze Ingestion Standard)
-- Usage: High-volume, automated continuous ingestion from cloud storage (AWS S3).
-- ==============================================================================

-- A. Create the External Stage pointing to S3
CREATE OR REPLACE STAGE STG_EXTERNAL_AWS_RAW
    URL = 's3://omni-retail-prod-raw/shopify/'
    STORAGE_INTEGRATION = S3_PROD_INTEGRATION
    FILE_FORMAT = DB_PROD_METADATA.SC_META_FORMATS.FF_JSON_GENERIC;

-- B. Pipeline Usage: Snowpipe auto-ingests from this stage into the raw table.
-- The external stage acts as the bridge between Snowflake compute and AWS storage.
CREATE OR REPLACE PIPE PIPE_SHOPIFY_ORDERS
    AUTO_INGEST = TRUE
AS
    COPY INTO TB_RAW_SHOPIFY_ORDERS (raw_payload, file_name, file_row_number, loaded_at)
    FROM (
        SELECT $1, metadata$filename, metadata$file_row_number, CURRENT_TIMESTAMP()
        FROM @STG_EXTERNAL_AWS_RAW/orders/
    );


-- ==============================================================================
-- 2. NAMED INTERNAL STAGE PIPELINE (The Snowpark & Artifact Standard)
-- Usage: Secure, shared internal storage for Python code, ML models, or shared CSVs.
-- ==============================================================================

-- A. Create the Named Internal Stage with Directory Tables Enabled
CREATE OR REPLACE STAGE STG_INTERNAL_ARTIFACTS
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Shared internal stage for Snowpark Python artifacts and ML models';

-- B. Pipeline Usage (Run in SnowSQL/Python): Upload local artifacts to the stage
-- PUT file:///app/build/data_quality_udf.zip @STG_INTERNAL_ARTIFACTS/python_code/ AUTO_COMPRESS=FALSE;

-- C. Pipeline Usage: Dynamically query the Directory Table to monitor deployments
SELECT 
    RELATIVE_PATH, 
    SIZE AS FILE_SIZE_BYTES, 
    LAST_MODIFIED, 
    MD5 
FROM DIRECTORY(@STG_INTERNAL_ARTIFACTS)
WHERE RELATIVE_PATH LIKE '%.zip';


-- ==============================================================================
-- 3. TABLE STAGE PIPELINE (The Tightly Coupled Standard)
-- Usage: Automated batch uploads that belong to ONE specific table only.
-- ==============================================================================

-- A. Pipeline Usage (Run in SnowSQL/Python): A downstream application pushes a 
-- daily batch file directly into the internal stage attached to the table.
-- PUT file:///tmp/daily_pos_transactions_20231015.csv @%TB_RAW_POS_TRANSACTIONS;

-- B. Pipeline Usage: Load the file into the table. 
-- Notice we use `@%` followed by the table name.
COPY INTO TB_RAW_POS_TRANSACTIONS
FROM @%TB_RAW_POS_TRANSACTIONS
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

-- C. Pipeline Usage: Clean up the stage after loading to save storage costs
REMOVE @%TB_RAW_POS_TRANSACTIONS pattern='.*.csv.gz';


-- ==============================================================================
-- 4. USER STAGE PIPELINE (The Ad-Hoc / Developer Standard)
-- Usage: A single user testing logic with local data files. NOT for production.
-- ==============================================================================

-- A. Pipeline Usage (Run in SnowSQL/Python): A Data Engineer uploads a local 
-- mapping file to their personal, private internal stage.
-- PUT file:///Users/developer/test_mapping.csv @~;

-- B. Pipeline Usage: Check that the file uploaded successfully.
-- Note: You CANNOT use `SELECT * FROM DIRECTORY(@~);` here.
LIST @~;

-- C. Pipeline Usage: Load the personal file into a temporary development table
CREATE OR REPLACE TEMPORARY TABLE TB_DEV_MAPPING_TEST (
    source_id VARCHAR,
    target_id VARCHAR
);

COPY INTO TB_DEV_MAPPING_TEST
FROM @~/test_mapping.csv.gz
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

-- D. Pipeline Usage: Delete the file from the personal stage
REMOVE @~/test_mapping.csv.gz;
