/* ==============================================================================
 * FILE: 05_task_monitoring_views.sql
 * PHASE: 08 - CDC Framework (Module 3)
 * 
 * EXPLANATION: Provides operational views over the Snowflake Task DAG to track execution history, detect failures, and monitor SLA breaches.
 * DESIGN DECISIONS: Queries INFORMATION_SCHEMA.TASK_HISTORY to parse execution states, errors, and run durations. Creates a specific SLA breach view to alert if the root task hasn't succeeded in the last 60 minutes.
 * WHY: Task history is transient (typically 7 days); these views surface critical failures for alerting tools. SLA monitoring ensures data freshness guarantees are met, and alerting logic is decoupled from the tasks themselves.
 * ============================================================================== */

USE ROLE SYSADMIN;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_PIPELINE;

-- 1. View: Task Execution History
-- Parses the Snowflake TASK_HISTORY to surface failed executions and retries.
CREATE OR REPLACE SECURE VIEW VW_TASK_EXECUTION_HISTORY AS
SELECT 
    NAME AS TASK_NAME,
    STATE AS EXECUTION_STATE,
    RETURN_VALUE,
    QUERY_ID,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_CODE,
    ERROR_MESSAGE,
    DATEDIFF('second', SCHEDULED_TIME, COMPLETED_TIME) AS DURATION_SECONDS
FROM TABLE(DB_PROD_CURATED.INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('days', -7, CURRENT_TIMESTAMP())
))
ORDER BY SCHEDULED_TIME DESC;

-- 2. View: DAG SLA Monitor
-- Identifies if the CDC Root task hasn't completed successfully in the last hour.
CREATE OR REPLACE SECURE VIEW VW_DAG_SLA_BREACHES AS
SELECT 
    'TSK_CDC_MASTER_SCHEDULE' AS ROOT_TASK_NAME,
    MAX(COMPLETED_TIME) AS LAST_SUCCESSFUL_COMPLETION,
    DATEDIFF('minute', MAX(COMPLETED_TIME), CURRENT_TIMESTAMP()) AS MINUTES_SINCE_SUCCESS,
    CASE 
        WHEN DATEDIFF('minute', MAX(COMPLETED_TIME), CURRENT_TIMESTAMP()) > 60 THEN 'SLA BREACH'
        ELSE 'HEALTHY'
    END AS SLA_STATUS
FROM TABLE(DB_PROD_CURATED.INFORMATION_SCHEMA.TASK_HISTORY())
WHERE NAME = 'TSK_CDC_MASTER_SCHEDULE' 
  AND STATE = 'SUCCEEDED';
