# OmniRetail Platform - Comprehensive Operations Runbook

This runbook is the centralized guide for executing, monitoring, and troubleshooting the OmniRetail Data Platform. It expands upon the Daily SOP to provide a complete operational manual.

## 1. Daily Operations & Health Checks

Perform these checks daily by 08:00 AM local time.

### A. Core Platform Health
- **Snowflake Warehouses:** Ensure all warehouses are `STARTED` or `SUSPENDED`. None should be stuck in `RESIZING`.
- **Airflow Orchestrator:** Verify `enterprise_master_orchestrator_dag` ran successfully. Check `Browse -> SLA Misses` for any delays.
- **dbt Cloud:** Verify all overnight jobs succeeded and all data quality tests passed.

### B. Ingestion (Snowpipe) Validation
Check for any files that failed to load into the Bronze layer:
```sql
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'OMNIRETAIL.RAW.BRONZE_LANDING',
    START_TIME => DATEADD(hour, -24, CURRENT_TIMESTAMP())
))
WHERE STATUS != 'LOADED';
```
> [!WARNING]
> If files show `LOAD_FAILED`, this usually indicates schema drift from the source system or malformed JSON payloads.

### C. Data Freshness & CDC Tracking
Verify that Snowflake Streams are actively tracking changes and the Gold layer is fresh:
```sql
-- Check CDC stream health
SHOW STREAMS IN DATABASE OMNIRETAIL; 

-- Check Gold table freshness (Should be < 4 hours stale)
SELECT table_name, DATEDIFF(hour, last_altered, CURRENT_TIMESTAMP()) AS hours_stale
FROM snowflake.account_usage.tables
WHERE table_schema = 'GOLD' AND deleted IS NULL
ORDER BY hours_stale DESC;
```

## 2. Common Execution Workflows (How-To)

### Deploying a New Pipeline
We use a YAML-driven approach to generate Airflow DAGs. 
1. Navigate to the central registry: `domain_config.yaml`.
2. Add the configuration for your new source (tables, schedule, dependencies).
3. Commit and push to GitHub.
4. The **Dynamic DAG Factory** will automatically parse the YAML and generate the Airflow UI tasks.

### Running a Manual dbt Backfill
If you need to rebuild a historical table due to logic changes:
1. Do **not** run dbt on the Airflow worker.
2. Trigger the job via Airflow using the `DbtCloudRunJobOperator`, or trigger directly in dbt Cloud.
3. For full refreshes, use the `--full-refresh` flag carefully to avoid excessive Snowflake compute costs.

## 3. Incident Response & Troubleshooting

### Scenario 1: Airflow Scheduler Crashes
- **Cause:** Often caused by top-level Python code querying the database during DAG parsing.
- **Resolution:** Our architecture mitigates this since Airflow is stateless. MWAA/Kubernetes will auto-restart the pod. DAGs will resume from failure points. Ensure developers are not bypassing the YAML registry.

### Scenario 2: Snowflake Compute Spike (>100 Credits/Day)
- **Cause:** A runaway cross-join query or an improperly scaled warehouse.
- **Resolution:**
  1. Check the `account_usage.warehouse_metering_history`.
  2. Identify the offending query in the Top 20 Expensive Queries dashboard.
  3. Ensure the Terraform safeguard (`statement_timeout_in_seconds = 3600`) is active.

### Scenario 3: dbt Test Failures (Data Quality)
- **Cause:** Upstream data violations (e.g., null primary keys, unaccepted values).
- **Resolution:** 
  1. The pipeline will automatically halt to prevent bad data from reaching the Gold layer.
  2. The bad records are routed to the **Dead Letter Queue (DLQ)** / Quarantine.
  3. Investigate the quarantine tables, fix the upstream data, or adjust the dbt tests if the business logic changed.

> [!IMPORTANT]
> All infrastructure changes must be applied via **Terraform**. All data transformations must run through **dbt Cloud**. Manual interventions in the Snowflake UI should be restricted strictly to read-only investigations.
