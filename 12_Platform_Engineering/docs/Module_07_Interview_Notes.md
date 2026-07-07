# Interview Notes: Enterprise Observability

## Q: What is Data Observability and why is it different from monitoring?
**A:** "Monitoring tells you *what* is broken—a DAG failed, a dbt test failed. Observability tells you *why* it broke. I built a Data Observability framework that measures 5 pillars: **Freshness** (when was data last updated?), **Volume** (did the expected number of rows arrive?), **Schema** (did columns change?), **Completeness** (are critical fields NULL?), and **Accuracy** (do aggregates match known business rules?). All 5 checks are SQL queries against `SNOWFLAKE.ACCOUNT_USAGE` views, scheduled via Airflow every 15 minutes."

## Q: How do you detect data quality issues before users report them?
**A:** "I implement proactive anomaly detection. For Volume, I compare today's row count against the 7-day rolling average. If `FCT_SALES` normally receives 100K rows/day but today only has 5K, the check flags a `🔴 VOLUME ANOMALY`. For Schema Drift, I query the `COLUMNS` view for any column created in the last 24 hours. For Freshness, I check `last_altered` timestamps against the expected SLO."

## Q: How do you reduce MTTR (Mean Time to Resolution)?
**A:** "Three things: First, **runbooks**. Every SEV-1 and SEV-2 alert links directly to a specific runbook with step-by-step resolution instructions. Second, **severity routing**. My `enterprise_alert_router` ensures SEV-1 hits PagerDuty and SEV-3 goes to Slack, so engineers aren't overwhelmed by low-priority noise. Third, **RCA templates**. After every incident, we fill out a structured Root Cause Analysis with a timeline, contributing factors, and action items. This prevents the same incident from recurring."

## Q: What are SLIs, SLOs, and SLAs in a data platform?
**A:** "I follow Google's SRE framework. The **SLI** is the measurable signal—for us, it's `hours_since_last_dbt_build`. The **SLO** is the internal engineering target—Gold must be refreshed within 4 hours, 99.5% of days. The **SLA** is the contractual promise to the business—the Finance VP is guaranteed that Power BI dashboards show data no older than 4 hours. If we breach the SLO, engineering investigates. If we breach the SLA, it triggers a formal Post-Incident Review."
