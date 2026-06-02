# Phase 10 - Module 3: Enterprise Staging Layer

This module introduces the Foundation of the Medallion Architecture (Silver). The staging layer provides a pristine 1:1 mapped view of the raw bronze sources.

## Deliverables Checklist

- [x] **Repository Structure:** Created directory structure under `models/staging/` to logically separate source systems (Shopify, Oracle ERP, Stripe, etc.).
- [x] **Staging Models:** Implemented models (e.g., `stg_orders`, `stg_payments`, `stg_inventory`) strictly enforcing technical standardization without leaking business logic.
- [x] **Defensive Standardization:** Utilized `dbt_utils.deduplicate` for append-only streams, explicitly cast timestamps to `UTC`, standardized boolean flags, and established explicit primary key alias mapping.
- [x] **Configuration & Metadata:** Developed the `schema.yml` file, adhering to the custom AGENTS rules by including Materialization Justification, Downstream Dependencies, and robust `dbt-expectations` testing.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_03_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_03_Runbook.md).md) detailing why staging models must be materialized as views and must not contain table joins.

## Usage Example (Testing Staging Models)
```bash
# Run and test all staging models targeting the Dev environment
dbt build --select tag:layer:staging --target dev
```
