# Phase 10 - Module 5: Enterprise Dimension Models

This module establishes the Kimball Dimensional Modeling layer, acting as the Single Source of Truth (SSOT) for the business entities that slice and dice our Fact data.

## Deliverables Checklist

- [x] **Repository Structure:** Placed all models under `models/marts/dimensions/`.
- [x] **Conformed Dimensions:** Implemented `dim_date.sql` using the `dbt_utils.date_spine` macro. This integer-based `date_sk` is the highest-performing way to join Facts to Dates in Snowflake.
- [x] **Surrogate Keys & Handling Late Arriving Data:** Implemented `dim_customer.sql` and `dim_product.sql`, exposing the `customer_sk` surrogate keys generated in the intermediate layer, and explicitly `UNION`ing a `-1` UNKNOWN record to protect against Fact table orphans.
- [x] **Configuration & Metadata:** Developed the `schema.yml` file, adhering to the AGENTS rules. Justified the use of `table` materializations for fast columnar scanning.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_05_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_05_Runbook.md).md) detailing how to prevent Cartesian Explosions and defend the Star Schema vs OBT (One Big Table) architectures.

## Usage Example (Testing Dimensions)
```bash
# Run and test all dimensional models
dbt build --select tag:type:dimension --target dev
```
