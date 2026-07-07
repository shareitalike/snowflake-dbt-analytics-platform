-- ==============================================================================
-- 14_replay_metadata_tables.sql
-- Description: Physical schema for Replay Queues and Recovery Logs
-- Phase: 08 - CDC Framework (Module 7)
-- ==============================================================================

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_CONTROL;

-- ------------------------------------------------------------------------------
-- 1. FAILED BATCH REGISTRY
-- ------------------------------------------------------------------------------
-- Automatically populated by VW_FAILED_BATCHES to isolate batches that require replay
CREATE OR REPLACE SECURE VIEW VW_FAILED_BATCH_REGISTRY AS
SELECT 
    Batch_ID,
    Pipeline_ID,
    Pipeline_Run_ID,
    Status,
    Low_Watermark,
    Error_Message,
    Execution_Start_Time
FROM TB_BATCH_CONTROL
WHERE Status = 'FAILED';

-- ------------------------------------------------------------------------------
-- 2. REPLAY QUEUE
-- ------------------------------------------------------------------------------
-- IT Operations registers replay requests here via an ITSM integration (e.g., ServiceNow)
CREATE TABLE IF NOT EXISTS TB_REPLAY_QUEUE (
    Replay_Request_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    Pipeline_ID VARCHAR(50),
    Replay_Type VARCHAR(50), -- BATCH, DATE_RANGE, FILE, DOMAIN
    Target_Batch_ID VARCHAR(36),
    Start_Timestamp TIMESTAMP_LTZ,
    End_Timestamp TIMESTAMP_LTZ,
    Target_Filename VARCHAR(255),
    Requested_By VARCHAR(100) DEFAULT CURRENT_USER(),
    ITSM_Ticket_Number VARCHAR(50),
    Status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, IN_PROGRESS, COMPLETED, FAILED
    Created_At TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ------------------------------------------------------------------------------
-- 3. RECOVERY LOG & AUDIT
-- ------------------------------------------------------------------------------
-- Immutable audit log of all executed replay and recovery operations
CREATE TABLE IF NOT EXISTS TB_RECOVERY_LOG (
    Log_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    Replay_Request_ID VARCHAR(36) REFERENCES TB_REPLAY_QUEUE(Replay_Request_ID),
    Action_Type VARCHAR(50), -- STREAM_RECREATION, WATERMARK_ROLLBACK, REPLAY_EXECUTION
    Pipeline_ID VARCHAR(50),
    Details VARIANT,
    Executed_By VARCHAR(100) DEFAULT CURRENT_USER(),
    Execution_Timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);
