# Operational Runbook: dbt Cloud Integration

## Common Production Issues

### 1. Authentication Expiry / Connection Denied
**Symptom:** Airflow task immediately fails with `401 Unauthorized` hitting the dbt Cloud API.
**Root Cause:** The Service Account Token stored in the Airflow Connection `dbt_cloud_default` has expired or was revoked.
**Resolution:**
Navigate to dbt Cloud -> Account Settings -> Service Tokens. Generate a new token with "Job Admin" privileges. Go to Airflow (or AWS Secrets Manager) and update the token. The DAG can be immediately restarted.

### 2. API Rate Limits
**Symptom:** Task fails with `429 Too Many Requests`.
**Root Cause:** Too many Airflow sensors are polling dbt Cloud job statuses concurrently using a tight `poke_interval` (e.g., 5 seconds).
**Resolution:**
Ensure all `DbtCloudRunJobOperator` instances have a `check_interval` of at least 60 seconds. Alternatively, utilize `deferrable=True` to consolidate polling.

### 3. Artifact Retrieval Failure
**Symptom:** The `extract_run_results` Python task fails.
**Root Cause:** The upstream dbt Cloud job failed during compilation, so the `run_results.json` artifact was never generated.
**Resolution:**
The Airflow task is behaving correctly by failing. Address the root compilation error in dbt Cloud, then clear the Airflow `dbt_build` task to re-run the chain.
