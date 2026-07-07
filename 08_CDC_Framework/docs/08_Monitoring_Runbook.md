# Production Runbook: Observability & Alerting

## 1. Freshness SLA Breach
**Symptom:** You receive a PagerDuty alert: "Pipeline SLA breached. Data latency is 120 minutes."
**Action:** 
1. Check `VW_RECENT_TASK_FAILURES` to see if the Task DAG has crashed. If so, fix the data issue and run `SP_REPLAY_FAILED_BATCH` (Module 7).
2. Check `VW_SNOWPIPE_LATENCY`. If the Snowflake Task is running cleanly but Snowpipe hasn't ingested files, check the AWS SNS/SQS queue integration. The source system may be down.

## 2. Warehouse Saturation & Credit Exhaustion
**Symptom:** `VW_WAREHOUSE_CREDIT_USAGE` shows a massive spike in Cloud Services or Compute credits for `WH_TRANSFORM`.
**Cause:** Someone modified the Task DAG and removed the `WHEN SYSTEM$STREAM_HAS_DATA` clause, causing the warehouse to spin up every 15 minutes even when no data exists. Alternatively, a Cartesian join was introduced into a `MERGE` statement, causing tasks to time out after 15 minutes of max CPU utilization.
**Action:** 
Immediately review the `Query Profile` for the longest-running queries executed by `WH_TRANSFORM` today.

## 3. Resolving Alerts
**Symptom:** The SLA alert keeps firing in the dashboard.
**Action:** 
Once an engineer acknowledges and fixes the pipeline issue, they MUST mark the alert as resolved to clear the dashboard:
`UPDATE TB_ALERT_QUEUE SET Is_Resolved = TRUE, Resolved_At = CURRENT_TIMESTAMP() WHERE Alert_ID = '...';`
