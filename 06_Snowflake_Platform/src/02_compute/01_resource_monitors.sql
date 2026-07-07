-- ==============================================================================
-- 01_resource_monitors.sql
-- Description: Financial Guardrails and Cost Optimization Limits
-- ==============================================================================

USE ROLE ACCOUNTADMIN;

-- Ingestion Monitor (Snowpipe / Sensor Polling)
CREATE RESOURCE MONITOR IF NOT EXISTS RM_INGESTION
    WITH CREDIT_QUOTA = 600
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS ON 80 PERCENT DO NOTIFY
             ON 100 PERCENT DO SUSPEND;

-- Transformation Monitor (dbt Cloud)
CREATE RESOURCE MONITOR IF NOT EXISTS RM_DBT_TRANSFORM
    WITH CREDIT_QUOTA = 3000
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS ON 80 PERCENT DO NOTIFY
             ON 100 PERCENT DO SUSPEND_IMMEDIATE;

-- BI Reporting Monitor (Power BI)
CREATE RESOURCE MONITOR IF NOT EXISTS RM_BI_REPORTING
    WITH CREDIT_QUOTA = 1200
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS ON 90 PERCENT DO NOTIFY
             ON 100 PERCENT DO SUSPEND;

-- Administrative & Ad-hoc Monitor
CREATE RESOURCE MONITOR IF NOT EXISTS RM_ADHOC
    WITH CREDIT_QUOTA = 500
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS ON 90 PERCENT DO NOTIFY
             ON 100 PERCENT DO SUSPEND;
