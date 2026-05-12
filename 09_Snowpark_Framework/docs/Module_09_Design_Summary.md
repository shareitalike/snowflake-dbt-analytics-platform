# Enterprise Metrics & Monitoring Framework
## Module 09 - Design Summary

### Operational Monitoring Strategy
Enterprise monitoring requires moving beyond passive logging to active observability. We track 4 core pillars:
1. **Pipeline Metrics:** Execution durations, records read/written/rejected, success rates.
2. **Data Quality (DQ) Metrics:** Null percentages, duplicate rates, referential integrity breaches.
3. **Business KPI Metrics:** Ensuring the actual data volume makes business sense (e.g. tracking a sudden 50% drop in GMV at the ingestion layer, which might indicate a source system API issue).
4. **Platform Health (FinOps):** Warehouse utilization, queue times, and credit consumption per pipeline.

### SLA & Alerting Framework
Monitoring is useless without actionable alerting. The `SLAMonitor` evaluates pipelines against predefined thresholds:
- **Freshness SLA:** Has the `TB_ORDERS_GOLD` table been updated in the last 15 minutes?
- **Latency SLA:** Did the Silver processing job take longer than 5 minutes?
- **Alert Routing:** We integrate an `AlertFramework` to route critical failures (Pipeline Crash) to PagerDuty/OpsGenie, while routing non-critical warnings (High Null Percentage) to a Data Stewards Slack channel.

### Metrics Collection Architecture
Snowpark pipelines utilize the `MetricsCollector` to aggregate statistics in memory during execution. Upon job completion, the `MetricsPublisher` flushes these standardized Pydantic models (like `PipelineMetrics` and `WarehouseMetrics`) to a unified `DB_PROD_METADATA.SC_MONITORING` schema. 
This structured metadata layer powers our operational dashboards in Snowsight and Power BI, allowing SREs to monitor the platform globally.
