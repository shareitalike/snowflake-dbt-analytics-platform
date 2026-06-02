# Phase 10 - Module 6: Enterprise Fact Models

This module establishes the final layer of the Medallion Architecture (Gold). Fact tables capture the measurable, transactional events of the business, modeled perfectly against the Conformed Dimensions.

## Deliverables Checklist

- [x] **Repository Structure:** Placed models in `models/marts/facts/`.
- [x] **Model Alignment:** Implemented `fct_sales.sql` and `fct_orders.sql`, explicitly aliased in Snowflake as `TB_SALES_FACT` and `TB_ORDER_FACT` to perfectly mirror the approved Phase 4 Enterprise Data Model.
- [x] **Performance Optimization:** All fact tables are heavily optimized. They utilize the `incremental` materialization (MERGE strategy) to process only the delta, and are explicitly `CLUSTER BY (date_sk)` to guarantee sub-second BI query performance.
- [x] **Operational Metadata:** As requested, every fact model contains explicit operational metadata documenting *Expected Row Counts*, *Refresh Frequency*, and *Downstream Consumers*. This data is persisted both in SQL comments and in the `schema.yml` `meta` tags.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_06_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_06_Runbook.md).md) detailing Fact table Grains, handling Double-Counting, and mitigating Late-Arriving Facts.

## Usage Example (Testing Incremental Fact Models)
```bash
# Run and test all fact models targeting the Dev environment
dbt build --select tag:type:fact --target dev
```
