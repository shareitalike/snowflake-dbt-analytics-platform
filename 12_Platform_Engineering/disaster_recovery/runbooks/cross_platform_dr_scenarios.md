# Enterprise DR Scenarios: Cross-Platform Recovery Playbooks
## Real-world failures with step-by-step recovery procedures

---

## SCENARIO A: Failed Production Deployment → Rollback via GitHub Actions + Terraform

**What happened:** A Terraform `apply` in the CI/CD pipeline accidentally changed `PROD_BI_WH` from `MEDIUM` to `XSMALL`, causing all Power BI dashboards to timeout.

**Detection:** The Operations Command Center shows `🔴 BI_WH: avg_queued_load = 42`. PagerDuty fires a SEV-1 alert.

**Recovery Steps:**
1. Open the GitHub Pull Request that caused the deployment.
2. Click **"Revert"** on the PR. GitHub automatically generates a revert commit.
3. The CI/CD pipeline triggers, runs `terraform plan`, and detects that `PROD_BI_WH` must be restored to `MEDIUM`.
4. The pipeline executes `terraform apply`, restoring the warehouse size.
5. Validate: Run `SHOW WAREHOUSES LIKE 'PROD_BI_WH';` — confirm size = `MEDIUM`.

**Recovery Time:** < 10 minutes. **Data Loss:** Zero.


---

## SCENARIO B: Snowflake Warehouse Outage → Workload Failover

**What happened:** `PROD_TRANSFORM_WH` is stuck in a `RESIZING` state and cannot process queries. The CDC MERGE pipeline is blocked.

**Detection:** Airflow `EnterpriseSnowflakeOperator` timeout triggers the `enterprise_alert_router`. SEV-2 alert fires.

**Recovery Steps:**
```sql
-- Step 1: Verify the stuck warehouse
SHOW WAREHOUSES LIKE 'PROD_TRANSFORM_WH';
-- If state = 'RESIZING' for > 10 minutes, it's stuck.

-- Step 2: Create an emergency failover warehouse
CREATE WAREHOUSE PROD_TRANSFORM_WH_FAILOVER
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE;

-- Step 3: Update the Airflow Variable to point to the failover warehouse
-- In Airflow UI → Admin → Variables:
-- Key: prod_variables
-- Update: "transform_warehouse": "PROD_TRANSFORM_WH_FAILOVER"

-- Step 4: Re-trigger the failed Airflow tasks (they will use the new warehouse)

-- Step 5: Once the original warehouse recovers, revert the Airflow Variable
-- and drop the failover warehouse.
DROP WAREHOUSE PROD_TRANSFORM_WH_FAILOVER;
```

**Recovery Time:** < 15 minutes. **Data Loss:** Zero (tasks retry automatically).

---

## SCENARIO C: Airflow Scheduler Failure → Resume Pending DAGs

**What happened:** The MWAA Scheduler pod crashed due to an OOM (Out of Memory) error. No DAGs have been parsed or scheduled for 45 minutes.

**Detection:** CloudWatch Alarm fires on the MWAA `SchedulerHeartbeat` metric dropping to zero.

**Recovery Steps:**
1. **MWAA auto-recovers:** AWS MWAA automatically restarts the Scheduler pod (managed service). Wait 2-3 minutes for the heartbeat to return.
2. **Verify recovery:** In the Airflow UI, check `Browse → DAG Runs`. Identify any DAG runs stuck in `queued` or `running` state.
3. **Clear stale task instances:**
   ```bash
   # Via Airflow CLI (or UI → DAG → Clear)
   airflow tasks clear enterprise_master_orchestrator_dag \
     --start-date 2025-07-07 --end-date 2025-07-07 \
     --only-failed
   ```
4. **Trigger backfill if needed:** If the daily 2:00 AM run was missed entirely:
   ```bash
   airflow dags trigger enterprise_master_orchestrator_dag \
     --execution-date 2025-07-07T02:00:00
   ```
5. **Validate:** Gold layer freshness returns to `🟢 FRESH` in the Operations Command Center.

**Recovery Time:** < 20 minutes. **Data Loss:** Zero (Airflow resumes from the last successful task).

---

## SCENARIO D: Corrupted dbt Deployment → Git Tag Rollback

**What happened:** A developer merged a dbt model change that introduced a circular reference. dbt Cloud's `dbt build` fails with `Compilation Error: Found a cycle`. The Gold layer is stale.

**Detection:** Airflow `DbtCloudRunJobOperator` returns `run_status = ERROR`. SEV-1 alert fires.

**Recovery Steps:**
1. **Identify the last successful Git tag:**
   ```bash
   git log --oneline --tags -5
   # Output: a3f8c21 (tag: v2.14.0) Successful release
   ```
2. **Revert to the last known-good state:**
   ```bash
   git revert HEAD   # Revert the bad commit
   git push origin main
   ```
3. **Re-trigger only the affected dbt models** (not a full rebuild):
   ```bash
   # Via dbt Cloud API or Airflow
   dbt build --select state:modified+ --defer --state ./target
   ```
4. **Validate:** Check `run_results.json` artifact — all tests must pass.

**Recovery Time:** < 25 minutes. **Data Loss:** Zero (Gold is rebuilt from Silver, which was unaffected).


---

## SCENARIO E: S3 Data Deletion → Restore from Versioning

**What happened:** A misconfigured lifecycle policy deleted 3 days of raw JSON files from `s3://omniretail-bronze-prod-landing/`.

**Detection:** Snowpipe `COPY_HISTORY` shows zero files loaded in the last 72 hours. Volume Anomaly check fires.

**Recovery Steps:**
```bash
# Step 1: List deleted objects (they still exist as delete markers in versioned bucket)
aws s3api list-object-versions \
  --bucket omniretail-bronze-prod-landing \
  --prefix raw/sales/ \
  --query 'DeleteMarkers[?LastModified>=`2025-07-04`]'

# Step 2: Remove the delete markers to restore the files
aws s3api delete-object \
  --bucket omniretail-bronze-prod-landing \
  --key raw/sales/2025-07-05/orders.json \
  --version-id "DELETE_MARKER_VERSION_ID"

# Step 3: Snowpipe will automatically re-ingest the restored files
# (if auto_ingest = true and SQS notifications are configured)

# Step 4: Verify in Snowflake
# SELECT COUNT(*) FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(...));
```

**Recovery Time:** < 30 minutes for targeted files. **Data Loss:** Zero (S3 Versioning preserves all previous versions).

