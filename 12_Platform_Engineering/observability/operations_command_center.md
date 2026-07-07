# Enterprise Operations Command Center
## Single-Pane-of-Glass Platform Dashboard

This document defines the unified Operations Command Center that consolidates real-time health metrics from every component in the OmniRetail Data Platform into a single operational view.

---

## Dashboard Layout (Grafana / Power BI)

```
┌─────────────────────────────────────────────────────────────────────┐
│                 OMNIRETAIL OPERATIONS COMMAND CENTER                │
│                    Last Refresh: 2025-07-07 09:15 UTC              │
├──────────────────────┬──────────────────────┬───────────────────────┤
│   SNOWFLAKE HEALTH   │    AIRFLOW HEALTH    │   dbt CLOUD HEALTH   │
│   🟢 5/5 Warehouses  │   🟢 12/12 DAGs OK   │   🟢 Last Build OK   │
│   Credits Today: 42  │   SLA Misses: 0      │   Tests: 187/187 ✅  │
│   Queries Queued: 0  │   Failed Tasks: 0    │   Runtime: 18 min    │
├──────────────────────┼──────────────────────┼───────────────────────┤
│     AWS HEALTH       │  GITHUB ACTIONS      │    POWER BI          │
│   🟢 S3: Healthy     │  🟢 Last Deploy OK   │   🟢 Refresh: 08:45  │
│   SQS Depth: 3       │  Commit: a3f8c21     │   Datasets: 6/6 OK   │
│   SNS Deliveries: OK │  Branch: main        │   Next: 12:00 UTC    │
├──────────────────────┴──────────────────────┴───────────────────────┤
│                      DATA OBSERVABILITY                            │
│   Freshness: 🟢 All Gold tables updated < 4h ago                   │
│   Volume:    🟢 No anomalies detected (7-day comparison)           │
│   Schema:    🟡 1 new column detected in BRONZE.RAW_CUSTOMERS      │
│   Quality:   🟢 All dbt tests passing (187/187)                    │
├─────────────────────────────────────────────────────────────────────┤
│                      FINOPS SUMMARY (MTD)                          │
│   Budget: $3,500  |  Spent: $2,246  |  Forecast: $2,890  | 🟢 OK  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Sources & Collection Method

| Platform | Data Source | Collection Method | Refresh |
|----------|-----------|-------------------|---------|
| **Snowflake** | `ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY` | SQL via Airflow Sensor | 15 min |
| **Snowflake** | `ACCOUNT_USAGE.QUERY_HISTORY` | SQL via Airflow Sensor | 15 min |
| **Snowflake** | `ACCOUNT_USAGE.RESOURCE_MONITORS` | SQL via Airflow Sensor | 15 min |
| **Airflow** | StatsD → Prometheus → Grafana | Push metrics (statsd_exporter) | Real-time |
| **Airflow** | Airflow REST API (`/api/v1/dags`) | Python script via cron | 5 min |
| **dbt Cloud** | dbt Cloud Admin API (`/api/v2/runs/`) | Airflow `DbtCloudRunJobOperator` callback | Per run |
| **AWS S3** | CloudWatch Metrics (`NumberOfObjects`) | CloudWatch Dashboard | 5 min |
| **AWS SQS** | CloudWatch Metrics (`ApproximateNumberOfMessagesVisible`) | CloudWatch Alarm | 1 min |
| **GitHub** | GitHub Actions API (`/repos/.../actions/runs`) | Webhook → SNS → Lambda | Per event |
| **Power BI** | Power BI REST API (`/groups/.../datasets/.../refreshes`) | Airflow HTTP Operator | 30 min |

---

## SQL Queries Powering the Dashboard

### Panel 1: Snowflake Health
```sql
-- Real-time warehouse status
SELECT 
    warehouse_name,
    state,
    CASE WHEN state = 'SUSPENDED' THEN '⚪' 
         WHEN state = 'STARTED' THEN '🟢'
         ELSE '🔴' END AS status_icon
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())); -- SHOW WAREHOUSES in production

-- Credits consumed today
SELECT 
    ROUND(SUM(credits_used), 2) AS credits_today
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATE_TRUNC('day', CURRENT_TIMESTAMP());
```

### Panel 2: Airflow Health
```sql
-- Query the Airflow metadata DB (via Airflow REST API, stored in METADATA_DB)
-- This table is populated by an Airflow DAG that writes its own health metrics to Snowflake.
SELECT 
    dag_id,
    last_run_state,
    last_run_duration_seconds,
    sla_miss_count_7d
FROM OMNIRETAIL.METADATA_DB.AIRFLOW_DAG_HEALTH
WHERE report_date = CURRENT_DATE();
```

### Panel 3: dbt Cloud Health
```sql
-- Populated by the dbt Cloud API client (built in Phase 11, Module 6)
SELECT 
    job_name,
    run_status,
    total_tests,
    tests_passed,
    tests_failed,
    run_duration_seconds
FROM OMNIRETAIL.METADATA_DB.DBT_RUN_RESULTS
WHERE run_date = CURRENT_DATE()
ORDER BY run_started_at DESC LIMIT 1;
```

### Panel 4: Data Observability Summary
```sql
-- Aggregated from the data_observability_checks.sql output
SELECT 
    'Freshness' AS pillar,
    SUM(CASE WHEN freshness_status LIKE '%STALE%' THEN 1 ELSE 0 END) AS issues
FROM OMNIRETAIL.METADATA_DB.OBSERVABILITY_FRESHNESS
WHERE check_date = CURRENT_DATE()
UNION ALL
SELECT 
    'Volume',
    SUM(CASE WHEN volume_status LIKE '%ANOMALY%' THEN 1 ELSE 0 END)
FROM OMNIRETAIL.METADATA_DB.OBSERVABILITY_VOLUME
WHERE check_date = CURRENT_DATE();
```

---

## Alerting Integration

| Condition | Severity | Channel | Action |
|-----------|----------|---------|--------|
| Any Snowflake warehouse `avg_queued > 5` | SEV-2 | Slack `#data-ops-critical` | Scale cluster or redistribute workload |
| dbt tests failed > 0 | SEV-2 | Slack `#data-quality` | Investigate failing test, fix model |
| Gold table freshness > 4 hours | SEV-1 | PagerDuty | Trigger on-call, check Airflow DAG |
| SQS queue depth > 1000 | SEV-2 | Slack + CloudWatch Alarm | Investigate Snowpipe lag |
| GitHub Actions deploy failed | SEV-3 | Slack `#deployments` | Check CI logs, fix and re-push |
| Power BI refresh failed | SEV-3 | Email to BI team | Check dataset credentials |
| Monthly credits > 90% of budget | SEV-4 | Email to FinOps lead | Review warehouse utilization |

---

*"I built a unified Operations Command Center that consolidates metrics from Snowflake, Airflow, dbt Cloud, AWS, GitHub Actions, and Power BI into a single-pane-of-glass view. The key architectural decision was to use Snowflake itself as the metrics store. Every monitoring component writes its health status to `METADATA_DB`, and the dashboard queries those tables. This avoids introducing a separate metrics infrastructure like InfluxDB and keeps the entire observability stack within the tools we already operate."*
