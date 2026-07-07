# Phase 10 - Module 4: Enterprise Intermediate Layer

This module establishes the Core Business Logic engine of the Medallion Architecture. The intermediate layer bridges the gap between atomic, standardized `staging` entities and the fully aggregated `marts` dimensional layer.

## Deliverables Checklist

- [x] **Repository Structure:** Created highly structured directories under `models/intermediate/` organized by business domain (e.g., `customers/`, `orders/`, `payments/`).
- [x] **Business Transformations:** Implemented `int_orders_enriched.sql` to calculate `net_revenue` and generate Surrogate Keys (`_sk`) early in the pipeline.
- [x] **Seed Reference Integration:** Implemented `int_payments_reconciled.sql` to demonstrate joining dynamic staging data (`stg_payments`) against Git-controlled Seed data (`payment_methods.csv`) to calculate Gateway Fees.
- [x] **Data Enrichment:** Implemented `int_customers_enriched.sql` to aggregate lifetime values and segment customers into `VIP`, `Active`, or `Occasional` tiers.
- [x] **Configuration & Metadata:** Developed the `schema.yml` file, adhering to AGENTS rules. Crucially, demonstrated the materialization trade-off between `ephemeral` (for lightweight pass-through logic) and `table` (for heavy aggregations referenced by multiple downstream marts).
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_04_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_04_Runbook.md).md) detailing how intermediate models prevent "spaghetti SQL" in the Marts layer and eliminate duplicated business logic.

## Usage Example (Testing Intermediate Models)
```bash
# Run all intermediate models, which will natively test unique constraints on the newly generated surrogate keys.
dbt build --select tag:layer:intermediate --target dev
```
