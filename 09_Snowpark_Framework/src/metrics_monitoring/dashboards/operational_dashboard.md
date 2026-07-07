# Operational Dashboard Specifications
Target Platform: Snowflake Snowsight & Power BI

## 1. Executive Platform Health (Power BI)
**Audience:** CDO, VP of Engineering, FinOps
**Metrics:**
- **Total Pipeline Success Rate:** (Target > 99.5%) - Bar chart by day.
- **Total Compute Cost (7 Days):** Snowflake Credits consumed across all pipelines.
- **Top 5 Most Expensive Pipelines:** Horizontal bar chart highlighting cost drivers.
- **Data Quality Health Score:** Aggregate score (0-100) combining Nulls, Duplicates, and Referentials.

## 2. Pipeline Execution Dashboard (Snowsight)
**Audience:** Data Engineers, SREs
**Metrics:**
- **Active Running Pipelines:** Table showing Pipeline ID, Start Time, and Current Duration.
- **Recent Failures:** Table filtered by `Status = 'FAILED'` showing Pipeline ID, Error Message, and Query ID.
- **Throughput:** Line chart plotting `Records Written` per hour.
- **Latency Trend:** Line chart plotting `Execution_Duration_Sec` over the last 30 days.

## 3. Data Quality & Stewardship (Snowsight)
**Audience:** Data Stewards, Analytics Engineers
**Metrics:**
- **Quarantine Volume:** Total rows sitting in DLQ tables (Requires action).
- **Missing References (Warnings):** Count of transactions mapped to `UNMAPPED` fallback values.
- **Schema Drift Log:** Table detailing any unexpected columns or type mismatches from upstream sources.
- **Freshness SLA Breaches:** List of tables that have breached their maximum allowed delay.
