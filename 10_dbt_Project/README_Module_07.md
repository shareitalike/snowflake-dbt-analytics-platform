# Phase 10 - Module 7: Enterprise Incremental Models Framework

This module establishes our advanced strategies for scaling Snowflake deployments using dbt incremental models. By processing only deltas (net-new or updated records), we prevent massive Full Table Scans, drastically reducing Snowflake FinOps credit burn.

## Deliverables Checklist

- [x] **Repository Structure:** Placed models in `models/incremental/` and created the `incremental_filter.sql` macro.
- [x] **Enterprise CDC Integration:** Implemented a robust Jinja macro (`generate_cdc_watermark`) that explicitly links the dbt pipeline to the output of our Phase 8 Snowflake Tasks CDC pipeline.
- [x] **Incremental Strategies:** Demonstrated the three primary strategies:
    - **`merge`:** Used in `fact_sales_incremental` to safely upsert late-arriving CDC data.
    - **`insert_overwrite`:** Used in `fact_inventory_incremental` to dynamically drop and replace daily Snowflake micro-partitions for massive snapshot data.
    - **`append`:** Used in `dim_customer_incremental` to build a rapid, insert-only audit log of customer mutations.
- [x] **Operational Metadata:** As established in Module 6, every model explicitly declares its *Expected Row Counts*, *Refresh Frequency*, and *Downstream Consumers*.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_07_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_07_Runbook.md).md) detailing how to manage Schema Drift (`on_schema_change`) and prevent Duplicate Records during Overwrites.

## Usage Example (Testing Incremental Models)
```bash
# Run incremental models targeting the Dev environment
dbt build --select tag:layer:incremental --target dev
```
