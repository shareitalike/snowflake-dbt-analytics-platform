# Enterprise Observability Platform
## Module 07 - Design Summary

### Monitoring vs Observability
**Monitoring** tells you *what* is broken (e.g., "dbt build failed"). **Observability** tells you *why* it broke (e.g., "Schema drift added a new column in Bronze that dbt's YAML schema didn't expect"). Our framework covers both:
- **Platform Health Checks:** Run every 15 minutes via Airflow, querying Snowpipe queues, stream lag, warehouse saturation, and failed logins.
- **Data Observability:** Measures the 5 pillars—Freshness, Volume, Schema Drift, Completeness, and Accuracy—using native Snowflake `ACCOUNT_USAGE` views.

### SLA / SLO / SLI Framework
We follow Google's SRE model to formalize reliability:
- **SLI (Indicator):** The measurable metric (e.g., `hours_since_last_dbt_build`).
- **SLO (Objective):** The internal target (e.g., Gold layer refreshed within 4 hours, 99.5% of days).
- **SLA (Agreement):** The contractual commitment to the business (e.g., Power BI dashboards reflect data no older than 4 hours).

### End-to-End Visibility
Rather than siloed monitoring per tool, we built a unified view. The Platform Health Check script runs in Airflow and queries across Snowflake (streams, warehouses, logins), dbt Cloud (via API artifact mining), and AWS (S3 event queues). If any check returns `UNHEALTHY`, the `enterprise_alert_router` (built in Module 8 of Phase 11) triggers the appropriate severity channel.
