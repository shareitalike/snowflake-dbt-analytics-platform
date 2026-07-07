# Module 8: Enterprise CDC Monitoring & Metadata Framework

## 1. Design Summary

### Why Metadata Framework & Observability?
An enterprise data platform operating without observability is flying blind. A robust Metadata Framework transforms the platform from a "black box" into a transparent, measurable system. It allows us to transition from reactive firefighting (e.g., waiting for business users to complain about stale data) to proactive intervention (e.g., auto-alerting engineering when CDC latency exceeds 15 minutes). 

### Business Benefits
* **SLA Guarantees:** Demonstrates exact data freshness metrics to business stakeholders.
* **FinOps Visibility:** Attributes warehouse credit consumption directly to specific pipelines, enabling accurate cost-to-serve models.
* **Operational Resilience:** Drastically reduces Mean Time to Detection (MTTD) and Mean Time to Resolution (MTTR) for pipeline failures.

## 2. Alert Framework Strategy
We utilize Snowflake's internal metadata combined with our explicit control tables (from Module 5) to generate actionable alerts:
1. **Failed Pipeline Alerts:** Triggers immediately if `TB_BATCH_CONTROL` registers a `FAILED` state.
2. **SLA Breach Alerts:** Triggers if the `TB_WATERMARK` is older than 60 minutes for a Near-Real-Time pipeline.
3. **Credit Threshold Alerts:** Triggers if the daily compute cost of `WH_TRANSFORM` exceeds the dynamic baseline by 20%.
4. **Data Freshness Alerts:** Triggers if the lag between the source `updated_at` and the target `created_at` exceeds the SLA.

## 3. Operational Dashboard Design

### Snowsight (Technical Dashboards)
Snowsight is utilized for real-time Engineering observability. Dashboards will map directly to the `VW_...` operational views to display:
* Currently Failed Tasks
* Stream Staleness Risk
* Warehouse Concurrency & Queueing

### Power BI (Business Dashboards)
Power BI will connect to the `DB_PROD_METADATA.SC_META_PIPELINE` schema via a service account to visualize:
* Daily Data Volume (Rows Ingested vs Updated)
* Pipeline SLA Compliance %
* Cost per Pipeline (Credits converted to USD)

## 4. Folder Structure
```text
08_CDC_Framework/
├── 08_Monitoring_Architecture.md
├── src/
│   ├── 17_monitoring_tables.sql       # Alert queues and history tables
│   ├── 18_monitoring_views.sql        # Cross-layer observational views
│   └── 19_monitoring_procedures.sql   # Alert generation procedures
├── tests/
│   └── 07_monitoring_tests.sql
├── 08_Monitoring_README.md
├── 08_Monitoring_Runbook.md
```
