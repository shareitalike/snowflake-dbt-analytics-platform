-- ==============================================================================
-- 06_task_rollback_scripts.sql
-- Description: Safe suspension and rollback of the CDC Task DAG
-- Phase: 08 - CDC Framework (Module 3)
-- ==============================================================================

USE ROLE DATA_ENGINEER;

-- ROLLBACK SCENARIO: The CDC logic needs to be paused for emergency maintenance 
-- or a massive historical backfill. 

-- 1. Suspend the Root Task
-- Suspending the root task prevents any new executions of the DAG.
-- Currently running tasks will complete.
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_MASTER_SCHEDULE SUSPEND;

-- 2. Optional: Suspend Children
-- If you need to drop/recreate a specific child task, you must suspend it first.
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_ORDERS SUSPEND;

-- 3. Drop Task DAG (Emergency Only)
-- If the DAG structure needs to be completely rebuilt.
-- DROP TASK IF EXISTS DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_MASTER_SCHEDULE;
-- DROP TASK IF EXISTS DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_CUSTOMER;
-- (etc...)
