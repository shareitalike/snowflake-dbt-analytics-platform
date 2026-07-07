# Operational Runbook: Observability Platform

## Common Production Issues

### 1. Data Freshness Alert — Gold Layer Stale
**Symptom:** The Freshness check flags `FCT_SALES` as `🔴 STALE: No update in 26h`.
**Root Cause:** The Airflow DAG that triggers dbt Cloud failed silently, or dbt Cloud itself had an outage.
**Resolution:**
1. Check the Airflow UI for the `enterprise_master_orchestrator_dag` run status.
2. If the DAG failed, check the `enterprise_alert_router` logs for the failure callback.
3. If dbt Cloud was down, verify via the dbt Cloud Status Page and re-trigger the job manually.
4. Once dbt completes, re-run the freshness check to confirm `🟢 FRESH`.

### 2. Volume Anomaly — Row Count Dropped 80%
**Symptom:** The Volume Anomaly query flags `FCT_SALES` with `🔴 ANOMALY: Row count dropped >50% vs 7-day avg`.
**Root Cause:** The upstream Snowpipe load failed for 3 source files, or the CDC stream was accidentally consumed without a corresponding MERGE.
**Resolution:**
1. Check `COPY_HISTORY` for failed loads in the last 24 hours.
2. If files failed, investigate the S3 event notifications and Snowpipe error messages.
3. If the stream was consumed prematurely, use Time Travel to restore the Bronze table state.

### 3. Schema Drift Detected
**Symptom:** The Schema Drift query flags a new column `LOYALTY_TIER` in `BRONZE.RAW_CUSTOMERS`.
**Root Cause:** The upstream source system (Salesforce) added a new field. Fivetran replicated it automatically, but dbt's `schema.yml` does not expect it.
**Resolution:**
1. This is NOT necessarily an error. Evaluate whether `LOYALTY_TIER` should be propagated to Silver/Gold.
2. If yes, update the dbt staging model and `schema.yml` to include it, then run `dbt build`.
3. If no, add it to the `.gitignore` column list in the dbt source definition.
