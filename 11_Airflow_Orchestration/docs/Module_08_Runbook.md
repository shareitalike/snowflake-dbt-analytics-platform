# Operational Runbook: Alerting & Monitoring

## Common Production Issues

### 1. Alert Fatigue (The "Boy Who Cried Wolf")
**Symptom:** Slack `#alerts-data-eng` receives 500 messages a day. Engineers ignore them.
**Root Cause:** The `enterprise_alert_router` was bypassed, and a junior engineer attached a blanket Failure Callback to every single DAG.
**Resolution:**
Audit all DAGs. Ensure they use the central `enterprise_alert_router`. Demote non-critical pipelines to `tier:3` so they do not trigger PagerDuty or global channels. 

### 2. Scheduler Heartbeat Failure
**Symptom:** Grafana Dashboard shows `airflow_scheduler_heartbeat` dropped to 0. No DAGs are running.
**Root Cause:** The Airflow Scheduler process crashed, or the Postgres DB is locked.
**Resolution:**
This triggers an automatic Sev-1 PagerDuty incident. The SRE must restart the Scheduler pod in Kubernetes or restart the EC2 service. Investigate the Postgres RDS metrics for CPU spikes caused by excessive `mode='poke'` sensors.

### 3. SLA Miss Escalation
**Symptom:** `enterprise_sla_miss_escalator` triggers at 8:00 AM for the `finance_pipeline_dag`.
**Root Cause:** An upstream data provider (e.g., Stripe) was 4 hours late delivering the end-of-month file, so the DAG sat in a "waiting" state.
**Resolution:**
The Data Engineer investigates via Airflow. Because it was an external delay, the SRE communicates the delay to the Finance team in the `#alerts-business-operations` channel. No engineering fix is required; it's a vendor management issue.
