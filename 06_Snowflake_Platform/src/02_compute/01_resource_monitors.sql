/* ==============================================================================
 * FILE: 01_resource_monitors.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Configures financial guardrails (Resource Monitors) across different compute domains (Ingestion, Transformation, BI, Ad-hoc).
 * DESIGN DECISIONS: Sets hard credit quotas on a monthly frequency. Different workloads have different trigger actions: dbt transformations trigger SUSPEND_IMMEDIATE, while BI and Ingestion trigger standard SUSPEND to allow running queries to finish.
 * WHY: Resource monitors prevent accidental run-away queries or infinite loops from consuming massive Snowflake credits (FinOps). Segmenting monitors by domain allows precise cost attribution and prevents one runaway team from shutting down the entire platform.
 * ============================================================================== */

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
