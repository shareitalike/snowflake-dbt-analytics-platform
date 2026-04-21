/* ==============================================================================
 * FILE: 06_task_rollback_scripts.sql
 * PHASE: 08 - CDC Framework (Module 3)
 * 
 * EXPLANATION: Contains scripts for safely suspending the CDC Task DAG for maintenance, backfilling, or emergency pauses.
 * DESIGN DECISIONS: Focuses on suspending the root task first to halt new DAG executions while allowing currently running child tasks to finish gracefully.
 * WHY: Suspending tasks gracefully prevents data corruption or partial merges that could happen if processes were violently killed. It provides a controlled mechanism for engineers to intervene during incidents.
 * ============================================================================== */

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
