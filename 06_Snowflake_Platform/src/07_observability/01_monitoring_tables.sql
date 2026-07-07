-- ==============================================================================
-- 01_monitoring_tables.sql
-- Description: Observability tables for custom platform telemetry
-- ==============================================================================

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_METADATA;

-- 1. Pipeline Execution Log
USE SCHEMA SC_META_PIPELINE;
CREATE TABLE IF NOT EXISTS TB_PIPELINE_LOG (
    Log_ID VARCHAR(36) DEFAULT UUID_STRING(),
    Execution_Time TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    Pipeline_Name VARCHAR(100),
    Status VARCHAR(20),
    Rows_Processed NUMBER,
    Error_Message VARCHAR
);

-- 2. Audit Quarantine Table (Dead Letter Queue)
-- Stores records that failed Snowpark validation logic
USE DATABASE DB_PROD_RAW;
CREATE SCHEMA IF NOT EXISTS SC_BRONZE_QUARANTINE;
USE SCHEMA SC_BRONZE_QUARANTINE;

CREATE TABLE IF NOT EXISTS TB_DLQ_PAYLOADS (
    DLQ_ID VARCHAR(36) DEFAULT UUID_STRING(),
    Quarantine_Time TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    Source_System VARCHAR(50),
    Raw_Payload VARIANT,
    Validation_Error VARCHAR
);
