/* ==============================================================================
 * FILE: 01_monitoring_tables.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Provisions custom observability tables for tracking pipeline execution metadata and a Dead Letter Queue (DLQ) for failed records.
 * DESIGN DECISIONS: Creates TB_PIPELINE_LOG to track batch executions and TB_DLQ_PAYLOADS to quarantine malformed raw data with UUID_STRING() default IDs.
 * WHY: Native Snowflake monitoring is sometimes transient (e.g., Task History drops after 7 days). Custom telemetry tables ensure long-term auditing for pipeline SLAs and provide a dedicated repository for engineers to debug failed records.
 * ============================================================================== */

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
