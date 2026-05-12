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

---

## 4. Financial Cost Optimization (FinOps) View (Power BI)
**Audience:** FinOps Team, Engineering Managers, CDO
**Goal:** Visualizing cost allocation and identifying waste.
*Note: This assumes the `TB_BATCH_CONTROL` table includes the `Cost` (USD) column populated by `SP_CALCULATE_COSTS`.*\n*   **Total Warehouse Cost (MTD):** Donut chart showing the breakdown of credits spent on different warehouses (e.g., `WH_TRANSFORM`, `WH_LOAD`, `WH_QA`).
*   **Compute Cost per Pipeline:** Vertical Bar Chart showing the cumulative cost for each pipeline (e.g., `PIPE_SHOPIFY_ORDERS`). This helps identify which pipelines are the biggest spenders.
*   **Cost per Record:** A KPI card showing the efficiency ratio (e.g., "$0.0024 per 1,000 records"). This metric helps answer the FinOps question: *"Are we getting better or worse at processing data for the money we spend?"*
