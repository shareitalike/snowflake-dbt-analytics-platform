# Enterprise Monitoring, Alerting & SLA Framework
## Module 08 - Design Summary

### Monitoring Strategy (Airflow + Prometheus/StatsD)
Enterprise Airflow clusters produce thousands of internal metrics per second. Rather than querying the Airflow Postgres database (which causes severe performance degradation), we configured Airflow to push metrics via StatsD to Prometheus. 
The `statsd_config.yaml` maps complex metric names to standardized formats, allowing us to build ultra-fast Grafana dashboards tracking `airflow_pool_open_slots` and `airflow_task_failures_total`.

### The Unified Operations Dashboard
An SRE should not have to open Airflow, then open Snowflake, then open dbt Cloud to understand platform health.
We designed `unified_operations_dashboard.json` (a Grafana export) that queries:
- **Prometheus** for Airflow scheduler health.
- **Snowflake JDBC** for Warehouse Credit Burn and Snowpark query execution times.
- **dbt Observability Data** (extracted via Airflow) for Medallion test failure rates.

### SLA Management vs. Task Failures
- A **Task Failure** is an engineering problem. E.g., "A Python task hit an Out of Memory error."
- An **SLA Miss** is a business problem. E.g., "The Finance dashboard was not refreshed by 8:00 AM."
We separate these entirely. Task Failures route to engineering Slack channels via the `enterprise_alert_router`. SLA Misses route to the Operations and Executive teams via the `sla_miss_handler`.

### Reducing Alert Fatigue
If 50 tasks fail in a DAG, you do not want 50 PagerDuty calls at 3:00 AM. 
The `enterprise_alert_router.py` intelligently inspects the DAG's tags. If it has `tier:1`, it triggers PagerDuty. If it has `tier:3`, it simply sends a Slack message to the specific domain channel (`#alerts-cx-data`). This ensures on-call engineers are only woken up for critical, revenue-impacting failures.
