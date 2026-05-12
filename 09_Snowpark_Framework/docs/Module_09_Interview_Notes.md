# Interview Notes: Metrics & Monitoring Framework

## Q: How do you monitor Snowpark pipelines?
**A:** "I build a unified `MetricsCollector` that runs alongside the pipeline. Instead of parsing text logs, the Snowpark job programmatically calculates `Records Read`, `Records Written`, and `Execution Duration`, packages them into a `PipelineMetrics` Pydantic object, and publishes them to a Snowflake Control Table. This provides structured, queryable telemetry that we expose via Snowsight operational dashboards."

## Q: How do you measure data quality in production?
**A:** "Data Quality is treated as a first-class operational metric. As pipelines evaluate data using our validation engine (Module 4), metrics like `Null Percentage`, `Duplicate Rate`, and `Schema Drift` are captured. If these breach a predefined threshold, the `AlertFramework` escalates a `WARNING` to the Data Stewards. We visualize these trends over time to catch silent data degradation before it reaches business reports."

## Q: How do you monitor warehouse costs and performance?
**A:** "FinOps is critical. Our framework captures `WarehouseMetrics` (Credit Consumption, Auto-Suspend configurations, Queue Time) per pipeline run. By correlating the `Pipeline_ID` with Snowflake's `QUERY_HISTORY` and `WAREHOUSE_METERING_HISTORY`, we calculate the exact dollar cost of every single pipeline run, allowing us to identify and refactor expensive transformations."

## Q: How do you implement SLA monitoring?
**A:** "We decouple SLA monitoring from the pipeline execution itself. The `SLAMonitor` is a scheduled task that queries the `PipelineMetrics` table. It calculates the `Freshness` of critical Gold tables (e.g., 'Has this table been updated in the last 1 hour?'). If it detects a breach, it fires a `CRITICAL` alert to PagerDuty. This ensures that even if a pipeline silently hangs and never writes a log, the independent SLA monitor will catch the missing data."

## Enterprise Best Practices Demonstrated
1. **Actionable Alerting:** Preventing alert fatigue by routing based on severity.
2. **FinOps Integration:** Tying technical execution metrics directly to Snowflake compute costs.
3. **Independent Observers:** Using a separate SLA Monitor to verify pipeline outcomes, protecting against silent failures.
