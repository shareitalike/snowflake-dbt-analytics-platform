# Daily Standard Operating Procedure (SOP)
## Morning Platform Health Check

**Owner:** On-Call Data Engineer / SRE  
**Frequency:** Daily, by 08:00 AM (local time)  
**Estimated Time:** 15 minutes

---

### 1. Operations Command Center Check
Navigate to the [Operations Command Center](../../observability/operations_command_center.md) dashboard.
- [ ] Verify **Snowflake Health**: All 5 warehouses are '🟢 STARTED' or '⚪ SUSPENDED' (None should be '🔴 RESIZING' or 'FAILED').
- [ ] Verify **Airflow Health**: `enterprise_master_orchestrator_dag` completed successfully overnight.
- [ ] Verify **dbt Cloud Health**: All tests passed (`187/187 ✅`). No compilation errors.
- [ ] Verify **AWS Health**: SQS depth is near zero.
- [ ] Verify **Data Observability**: Freshness and Volume checks are green.
- [ ] Verify **Power BI**: Scheduled refreshes completed successfully.

*If any check is Red/Yellow, immediately jump to the [Incident Response Playbook](../incident_response/rca_template_5whys.md).*

### 2. Snowflake Validation (Deep Dive)
Run the following checks directly in the Snowflake worksheet:

#### A. Snowpipe Validation
Ensure no files are stuck in the ingest queue:
```sql
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'OMNIRETAIL.RAW.BRONZE_LANDING',
    START_TIME => DATEADD(hour, -24, CURRENT_TIMESTAMP())
))
WHERE STATUS != 'LOADED';
```
*Action:* If files are `LOAD_FAILED`, investigate the S3 file format or schema drift.

#### B. Stream & Task Validation
Ensure CDC streams are actively advancing and not going stale:
```sql
SHOW STREAMS IN DATABASE OMNIRETAIL;
-- Check 'stale_after' column. Must be > 10 days in the future.
```

#### C. Credit Consumption Review
Check if we spiked yesterday:
```sql
SELECT warehouse_name, SUM(credits_used) 
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATE_TRUNC('day', DATEADD(day, -1, CURRENT_TIMESTAMP()))
GROUP BY 1;
```
*Action:* If total exceeds 100 credits/day, review the Top 20 Expensive Queries dashboard.

### 3. Airflow Health Check
Navigate to the Airflow UI (`http://airflow.omniretail.internal`).
- [ ] Check `Browse -> SLA Misses`. Create a Jira ticket for any pipeline that breached its SLA.
- [ ] Check `Admin -> Pools`. Ensure `snowflake_concurrent_pool` is not fully saturated (running tasks < slots).
- [ ] Check `Admin -> Connections`. Ensure AWS and Snowflake connections are valid (Test Connection).

### 4. Data Freshness Validation
Run the manual freshness query to confirm Gold layer readiness for the business day:
```sql
SELECT table_name, DATEDIFF(hour, last_altered, CURRENT_TIMESTAMP()) AS hours_stale
FROM snowflake.account_usage.tables
WHERE table_schema = 'GOLD' AND deleted IS NULL
ORDER BY hours_stale DESC;
```
*Action:* All critical tables should be < 4 hours stale.

### 5. Handover / Sign-off
Post a daily status update in the `#data-eng-general` Slack channel:
> "Morning Health Check complete. Platform is Green. No SLA misses. `PROD_BI_WH` credits normal."
