-- ==============================================================================
-- 02_task_tests.sql
-- Description: Validation scripts for the CDC Task DAG
-- Phase: 08 - CDC Framework (Module 3)
-- ==============================================================================

USE ROLE DATA_ENGINEER;

-- ==========================================
-- TEST CASE 1: Validate Task Dependencies
-- ==========================================
-- Ensure that TSK_CDC_ORDERS is correctly dependent on CUSTOMER and PRODUCT.
SHOW TASKS IN SCHEMA DB_PROD_CURATED.SC_UTILITIES;
-- Validation: Check the `predecessors` column in the output. 
-- TSK_CDC_ORDERS must list TSK_CDC_CUSTOMER and TSK_CDC_PRODUCT.

-- ==========================================
-- TEST CASE 2: Validate Task State
-- ==========================================
-- Verify all tasks are in a 'started' (RESUMED) state.
SELECT name, state, schedule 
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE state != 'started';
-- Validation: This query should return 0 rows if all tasks were resumed correctly.

-- ==========================================
-- TEST CASE 3: Execute DAG Manually
-- ==========================================
-- Force a manual run of the root task to bypass the 15-minute schedule.
EXECUTE TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_MASTER_SCHEDULE;

-- Monitor the manual run
SELECT * 
FROM TABLE(DB_PROD_CURATED.INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME=>'TSK_CDC_MASTER_SCHEDULE', 
    SCHEDULED_TIME_RANGE_START=>DATEADD(minute, -5, CURRENT_TIMESTAMP())
));
