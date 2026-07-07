-- ==============================================================================
-- 11_watermark_metadata_tables.sql
-- Description: Physical schema for Pipeline Control, Watermarks, and Batches
-- Phase: 08 - CDC Framework (Module 5)
-- ==============================================================================

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_METADATA;

-- The Operational Control Schema
CREATE SCHEMA IF NOT EXISTS SC_META_CONTROL;
USE SCHEMA SC_META_CONTROL;

-- ------------------------------------------------------------------------------
-- 1. PIPELINE METADATA
-- ------------------------------------------------------------------------------
-- Defines the registered pipelines that are allowed to execute
CREATE TABLE IF NOT EXISTS TB_PIPELINE_REGISTER (
    Pipeline_ID VARCHAR(50) PRIMARY KEY,
    Target_Table_Name VARCHAR(200),
    Source_Table_Name VARCHAR(200),
    Is_Active BOOLEAN DEFAULT TRUE,
    Created_By VARCHAR(100) DEFAULT CURRENT_USER(),
    Created_At TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ------------------------------------------------------------------------------
-- 2. WATERMARK TABLE
-- ------------------------------------------------------------------------------
-- Tracks the absolute highest successfully processed timestamp per pipeline
CREATE TABLE IF NOT EXISTS TB_WATERMARK (
    Pipeline_ID VARCHAR(50) REFERENCES TB_PIPELINE_REGISTER(Pipeline_ID),
    High_Watermark TIMESTAMP_LTZ NOT NULL,
    Last_Updated_At TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    Updated_By_Batch_ID VARCHAR(36)
);

-- ------------------------------------------------------------------------------
-- 3. BATCH CONTROL & CHECKPOINT TABLE
-- ------------------------------------------------------------------------------
-- Tracks individual executions, their bounds, and execution status
CREATE TABLE IF NOT EXISTS TB_BATCH_CONTROL (
    Batch_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    Pipeline_ID VARCHAR(50) REFERENCES TB_PIPELINE_REGISTER(Pipeline_ID),
    Pipeline_Run_ID VARCHAR(36), -- Ties together multiple batches in one DAG run
    Status VARCHAR(20) NOT NULL, -- STARTED, COMPLETED, FAILED
    Low_Watermark TIMESTAMP_LTZ,
    High_Watermark TIMESTAMP_LTZ,
    Rows_Extracted NUMBER DEFAULT 0,
    Rows_Inserted NUMBER DEFAULT 0,
    Rows_Updated NUMBER DEFAULT 0,
    Error_Message VARCHAR,
    Execution_Start_Time TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    Execution_End_Time TIMESTAMP_LTZ,
    Retry_Count NUMBER DEFAULT 0
);
