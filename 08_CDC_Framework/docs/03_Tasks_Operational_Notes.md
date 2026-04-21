# Production Runbook & Operational Notes: Task DAG

## 1. Task Failure
**Symptom:** The `VW_DAG_SLA_BREACHES` view reports an SLA BREACH, or a task in `VW_TASK_EXECUTION_HISTORY` shows `STATE = 'FAILED'`.
**Action:** 
1. Query `VW_TASK_EXECUTION_HISTORY` to find the specific `ERROR_MESSAGE` and `QUERY_ID`.
2. The failure will NOT corrupt data. Because a Task runs within an implicit transaction, the failure rolls back the `MERGE` and leaves the Stream offset untouched. 
3. Resolve the underlying data issue, then manually execute the failed child task using `EXECUTE TASK <task_name>`. The DAG will resume automatically on the next 15-minute interval.

## 2. Task Suspension (DAG Halting)
**Symptom:** The root task was accidentally suspended, stopping all CDC.
**Action:** 
Run `ALTER TASK TSK_CDC_MASTER_SCHEDULE RESUME;`. 
*Note: Ensure all child tasks are already in a `started` state before resuming the root task.*

## 3. Dependency Failure
**Symptom:** `TSK_CDC_CUSTOMER` fails. What happens to `TSK_CDC_ORDERS`?
**Answer:** `TSK_CDC_ORDERS` will automatically be skipped for that run. The DAG guarantees that downstream tasks do not execute if their predecessors fail. Once `CUSTOMER` is fixed and successfully executes, `ORDERS` will run in the subsequent batch.

## 4. Long-Running Tasks & Warehouse Timeout
**Symptom:** A task hits the `USER_TASK_TIMEOUT_MS` limit (15 mins) and aborts.
**Action:** 
1. Investigate the `MERGE` performance. Are micro-partitions heavily fragmented?
2. Temporarily increase the warehouse size (`ALTER WAREHOUSE WH_TRANSFORM SET WAREHOUSE_SIZE = 'LARGE'`) to clear the backlog.
3. Consider running `SYSTEM$CLUSTERING_INFORMATION` on the target table.

## 5. Duplicate Execution
**Symptom:** Can a task run twice and duplicate data?
**Answer:** No. 
1. Snowflake tasks guarantee at-most-once execution per schedule interval.
2. The `MERGE` statement is idempotent. Even if forced to run manually twice, it will update existing records rather than duplicating them.
