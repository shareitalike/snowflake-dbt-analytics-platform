# Interview Notes: Monitoring, Alerting & SLAs

## Q: How do you reduce Alert Fatigue in Airflow?
**A:** "In many companies, a single DAG failure triggers 50 emails, and engineers eventually set an Outlook rule to delete them all. To fix this, I build an **Intelligent Alert Router**. Every Airflow DAG is tagged with a Tier (`tier:1`, `tier:2`) and a Domain (`domain:sales`). If a `tier:3` DAG fails, the router just sends a quiet Slack message to the specific domain team. If a `tier:1` DAG fails, the router intercepts it and triggers a Sev-1 PagerDuty incident to wake up the on-call engineer. We only alert aggressively on revenue-impacting pipelines."

## Q: How do you implement SLA monitoring?
**A:** "A lot of people confuse Task Timeouts with SLAs. A timeout means a query hung for too long. An SLA means 'The business needs this data by 8:00 AM.' I implement SLAs natively in the Airflow DAG definition (`sla=timedelta(hours=4)`). If the DAG breaches that time, it triggers my custom `enterprise_sla_miss_escalator`, which pings the Business Operations team, because an SLA miss is a business issue, not just an engineering error."

## Q: How do you monitor the Airflow cluster itself?
**A:** "You should never query the Airflow Postgres database for metrics; that causes scheduler lockups. I configure Airflow to emit UDP metrics via StatsD to Prometheus. I then build a Grafana dashboard that visualizes `airflow_pool_open_slots` and `airflow_scheduler_heartbeat`. This allows me to see if my worker nodes are starving or if the scheduler crashed before a DAG even fails."

## Enterprise Best Practices Demonstrated
1. **Unified Dashboarding:** An enterprise doesn't use 4 different tools to check platform health. Our Grafana JSON pulls from Airflow, Snowflake, and dbt Cloud simultaneously.
2. **Severity Routing:** Treating alerting as a software engineering problem (building a router) rather than just a configuration toggle.
