# Enterprise Operations & Performance

## Performance Optimization (Snowflake + dbt)

At the enterprise scale, running a `SELECT *` without optimization can cost thousands of dollars per month. We employ strict performance strategies:

1. **Incremental Processing:** 
   - Massive Fact tables (`fct_sales`) use `incremental_strategy = 'merge'`. We never run a Full Refresh in production unless there is a destructive schema change.
   - Periodic Snapshots (`fact_inventory`) use `incremental_strategy = 'insert_overwrite'`, replacing dynamic micro-partitions instantly without row-by-row evaluation.
2. **Micro-partition Pruning & Cluster Keys:**
   - Every massive table defines `cluster_by = ['date_sk']` in its `dbt_project.yml` configuration. When a Power BI dashboard queries "Revenue for Q3", Snowflake skips scanning 95% of the physical disk (pruning), resulting in sub-second BI performance and massive cost savings.
3. **Warehouse Sizing (Compute Isolation):**
   - We utilize Snowflake Multi-Cluster Warehouses. dbt transformations run on an `XLARGE_ETL_WH`, while Power BI dashboards query an auto-scaling `MEDIUM_BI_WH`. This guarantees that heavy data transformations never lock up executive dashboards.

## Operational Monitoring & FinOps

1. **Pipeline SLA Monitoring:** Airflow alerts Slack/PagerDuty if the overarching `dbt build` takes longer than 45 minutes to execute.
2. **Test Results:** `severity: warn` tests do not break the pipeline, but their results are pushed to a centralized Data Quality Dashboard. Data Engineers track the "burn down" of these warnings over time.
3. **Warehouse Credits (FinOps):** Utilizing dbt Cloud's metadata API and Snowflake's `QUERY_HISTORY`, we tag every query executed by dbt with the model name. This allows us to build a dashboard showing exactly how many dollars were spent updating `fct_sales` vs `fct_inventory` this month, enabling rigorous ROI conversations with business units.

## Business Deliverables

The ultimate output of this architecture powers highly specific business domains:
- **Executive Sales Mart:** Consumes `fct_sales` and `dim_customer` to calculate Gross Margin and Net Revenue (governed by the Semantic layer).
- **Inventory Mart:** Consumes `fct_inventory_incremental` to power the SageMaker ML model that prevents multi-million dollar stockouts during Black Friday.
- **Marketing Mart:** Consumes `snap_customer` to track SCD Type 2 shifts in customer demographics, allowing granular attribution of Customer Acquisition Cost (CAC).
