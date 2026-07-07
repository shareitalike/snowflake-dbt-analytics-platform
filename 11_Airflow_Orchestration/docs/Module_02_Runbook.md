# Operational Runbook: Airflow Infrastructure

## Common Production Issues

### 1. Scheduler Down (Stalled DAGs)
**Symptom:** The Airflow UI shows a red banner saying "The scheduler does not appear to be running." No new tasks are moving from `queued` to `running`.
**Root Cause:** The Scheduler process crashed, or the Airflow Postgres Database maxed out its CPU/Memory, causing the Scheduler to lose its DB lock.
**Resolution:** 
1. Check RDS Postgres CPU metrics. If maxed, clear out old TaskInstance logs from the `log` table.
2. Restart the Scheduler service (or scale the Kubernetes pod to 0 then 1).

### 2. Worker Failure (OOM Kills)
**Symptom:** Tasks randomly fail with `SIGKILL` or `Negsignal 9`.
**Root Cause:** A Data Engineer wrote a PythonOperator that pulled a 5GB CSV file directly into the Airflow Worker's memory using Pandas, causing an Out of Memory (OOM) crash.
**Resolution:**
Airflow is an orchestrator, NOT a data processor. Refactor the code to use a `SnowflakeOperator` (which executes the compute in Snowflake) or push the compute to an AWS EMR cluster or AWS Lambda function.

### 3. Secret Rotation Failure
**Symptom:** All Snowflake Tasks fail simultaneously with `Authentication failed`.
**Root Cause:** The DBA rotated the Snowflake service account password, but AWS Secrets Manager was not updated.
**Resolution:**
Because we use AWS Secrets Manager as the Airflow backend, you simply update the JSON blob in AWS Secrets Manager. Airflow dynamically fetches the secret on every task execution, so the next retry will automatically succeed. No Airflow restart is required.
