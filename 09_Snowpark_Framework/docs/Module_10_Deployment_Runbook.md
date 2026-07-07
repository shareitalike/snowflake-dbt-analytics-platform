# Operational Runbook: End-to-End Orchestration

## Common Production Issues

### 1. The "Nothing Happened" Pipeline (Silent Failures)
**Symptom:** Airflow reports the pipeline ran successfully in 2 seconds, but the Silver tables weren't updated.
**Root Cause:** The `PipelineOrchestrator` traps all exceptions to guarantee the `AuditManager` flushes logs to the database. If Airflow doesn't check the *status* output of the orchestrator, it assumes exit code 0 means success.
**Resolution:** 
Ensure the Airflow `PythonOperator` explicitly checks the return object of the `PipelineOrchestrator.execute()` method. If the status is `FAILED`, the Airflow task must raise an `AirflowException` to halt downstream dbt jobs.

### 2. Massive DLQ Routing (Pipeline Degradation)
**Symptom:** The pipeline succeeds and hands off to dbt, but business users complain that GMV is 40% lower than expected.
**Root Cause:** A schema drift or upstream business logic error caused 40% of the orders to fail validation and route to the DLQ. The pipeline technically succeeded (because it handled the errors gracefully), but the business state is degraded.
**Resolution:**
The `AlertFramework` (Module 9) is configured to evaluate the `Success Rate` metric at the end of the orchestrator run. If the success rate drops below 95%, the orchestrator will fire a `CRITICAL` alert to PagerDuty, overriding the normal `SUCCESS` exit state.

### 3. Connection Pool Exhaustion (Thundering Herd)
**Symptom:** Snowpark jobs fail on startup with `SnowflakeConnectionException`.
**Root Cause:** Airflow triggered 100 historical catchup jobs simultaneously, hitting the Snowflake account connection limits.
**Resolution:**
The `SessionFactory` (Module 2) uses the `tenacity` exponential backoff jitter. Do not disable this in production. It naturally spaces out the connection requests. For massive backfills, restrict the Airflow DAG concurrency.
