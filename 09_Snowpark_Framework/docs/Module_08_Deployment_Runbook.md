# Operational Runbook: Audit & Metadata

## Common Production Issues

### 1. Incomplete Execution Logs (Zombie Pipelines)
**Symptom:** A pipeline in the Control Table shows a status of `STARTED` for 14 hours. It never reached `COMPLETED` or `FAILED`.
**Root Cause:** The pipeline experienced an abrupt termination (e.g., OOM kill by Kubernetes, or the Snowflake session dropped) before the `ExecutionTracker` could fire its `close()` method.
**Resolution:** 
1. Implement a timeout monitor in Airflow/Tasks to detect zombie runs. 
2. Use the Replay Framework (Module 7) to generate a new `Run_ID`. 
3. The framework's context manager (Module 2) is designed to trap exceptions and force a `FAILED` state, but hard network drops require external orchestration timeouts.

### 2. Missing Metadata / Orphaned Lineage
**Symptom:** A new dbt model appears in the Gold layer, but querying the Lineage Graph yields no upstream dependencies.
**Root Cause:** A data engineer created a manual SQL View without registering it in the Metadata Framework or dbt graph.
**Resolution:**
Audit policies must restrict DDL operations in `DB_PROD_GOLD` to the CI/CD service account only. Manual view creation should be revoked. Run the `LineageTracker.scan_orphans()` utility weekly to identify unmanaged assets.

### 3. Performance Bottleneck on Audit Writes
**Symptom:** Small, rapid micro-batches take 3 seconds to process data but 5 seconds to write audit logs to the Control Table.
**Root Cause:** Writing individual audit rows synchronously blocks pipeline completion.
**Resolution:**
The `AuditManager` utilizes Snowpark DataFrames to batch audit writes, but for extremely high-frequency streams, consider configuring the Audit logger to write to an asynchronous Kafka topic or Snowflake stage, rather than enforcing synchronous table inserts. For this Enterprise framework, we prioritize synchronous consistency unless latency strictly demands async.
