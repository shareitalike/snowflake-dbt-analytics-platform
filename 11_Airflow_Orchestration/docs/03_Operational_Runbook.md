# Operational Runbook: Airflow Platform

## Common Production Issues

### 1. The "Zombie" Task
**Symptom:** A task in the Airflow UI is marked as `running` for 14 hours, but the actual query in Snowflake finished in 2 minutes.
**Root Cause:** The Airflow Worker lost connection to the scheduler (e.g., the worker pod crashed or was preempted by Kubernetes) without updating the Airflow metastore database.
**Resolution:** 
Configure `execution_timeout` on all tasks (e.g., `execution_timeout=timedelta(hours=1)`). This instructs the Airflow Scheduler to forcefully mark the task as failed if it exceeds the expected SLA, preventing silent zombies.

### 2. XCom Bloat
**Symptom:** The Airflow Metastore database runs out of disk space, crashing the entire platform.
**Root Cause:** A Data Engineer used `XCom` (Cross-Communication) to pass a 50MB JSON payload from one task to another. `XCom` saves data directly into the Airflow Postgres database.
**Resolution:**
`XCom` should only be used for tiny metadata strings (e.g., passing a `job_id`). To pass large datasets between tasks, Task A must write the data to an AWS S3 bucket, and pass the *S3 URI string* via `XCom` to Task B. 

### 3. Connection Timeout Drops
**Symptom:** A heavy `SnowflakeOperator` query takes 4 hours, and Airflow marks the task as failed with a `Connection Closed` error, even though the query is still running perfectly in Snowflake.
**Root Cause:** The persistent TCP connection between the Airflow Worker and Snowflake was severed by an intermediate firewall due to idle inactivity.
**Resolution:**
Use the **Snowflake Deferrable Operator** (Async Operator). Instead of holding a persistent TCP connection open for 4 hours, the operator submits the query to Snowflake, immediately releases the Airflow Worker back to the pool, and occasionally polls Snowflake for completion. This uses 99% less compute and is immune to TCP timeouts.
