# Phase 11 - Module 8: Enterprise Monitoring, Alerting & SLA Framework

This module elevates our platform from a "data processing tool" to a "production-grade managed service." By implementing intelligent alerting, SLA tracking, and unified dashboards, we guarantee operational visibility and drastically reduce on-call alert fatigue.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `monitoring/`, `alerts/`, `sla/`, and `dashboards/`.
- [x] **Intelligent Alert Router (`enterprise_alert_router.py`):** Replaced blanket Airflow emails with a Python router that parses DAG tags. `tier:1` triggers PagerDuty. `domain:sales` routes to the Sales Slack channel.
- [x] **SLA Miss Handler (`sla_miss_handler.py`):** Separated engineering failures from business delivery failures by implementing an SLA Escalation matrix to Operations teams.
- [x] **Metrics Configuration (`statsd_config.yaml`):** Mapped Airflow's internal StatsD metrics for Prometheus ingestion.
- [x] **Unified Operations Dashboard (`unified_operations_dashboard.json`):** A production-ready Grafana export that provides a single pane of glass over Airflow Worker Health, Snowflake Credit Burn, Snowpark Execution times, and dbt Cloud Model Failures.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_08_Design_Summary.md) and [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_08_Runbook.md) detailing exactly how to handle Alert Fatigue and SRE principles.

## Usage Example (DAG Definition)
```python
from alerts.enterprise_alert_router import enterprise_alert_router
from sla.sla_miss_handler import enterprise_sla_miss_escalator

default_args = {
    'on_failure_callback': enterprise_alert_router,
    'sla': timedelta(hours=4),
}

dag = DAG(
    'sales_pipeline',
    default_args=default_args,
    sla_miss_callback=enterprise_sla_miss_escalator,
    tags=['domain:sales', 'tier:1']
)
```
