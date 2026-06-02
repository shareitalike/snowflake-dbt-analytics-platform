# Enterprise Fact Models
## Module 06 - Design Summary

### Purpose of Fact Tables
Fact tables form the center of the Star Schema. While dimensions describe the business context ("Who, what, where"), fact tables capture the **measurable events** of the business. By isolating facts from dimensions, we ensure a scalable, high-performance reporting layer for BI tools like Power BI.

### Fact Table Grain
The **grain** defines exactly what a single row in the fact table represents. This is the most critical decision in dimensional modeling; mixing grains leads to double-counting.
1. **Transaction Facts (`fct_sales`):** One row per sales line item. Captures highly granular metrics like product quantity and individual discount allocations.
2. **Accumulating Snapshot Facts (`fct_orders`):** One row per order header. Captures milestones (e.g., placed -> shipped -> delivered).
3. **Periodic Snapshot Facts (`fct_inventory_snapshot`):** One row per Product per Store per Day. Captures End-Of-Day stock balances.

### Measures
- **Additive:** Can be summed across any dimension (e.g., `Net Revenue`, `Quantity Sold`).
- **Semi-Additive:** Can be summed across some dimensions, but not Time (e.g., `Inventory Balance`. You cannot add Monday's inventory to Tuesday's inventory; you must take the End of Month average).
- **Non-Additive:** Cannot be summed (e.g., `Profit Margin %`). These must be recalculated in the BI layer as `Sum(Profit) / Sum(Revenue)`.

### Materialization Strategy
Due to the multi-billion row scale of enterprise fact tables, they are materialized incrementally.
- **`incremental` (MERGE strategy):** Instead of rewriting 5 years of history daily, the model only merges records where the `dbt_updated_at` from the upstream intermediate model is greater than the maximum date currently in the Fact table.
- **Alias configuration:** Models are named `fct_sales.sql` in the repository but compiled as `TB_SALES_FACT` in Snowflake to perfectly match the approved Phase 4 Enterprise Data Model.
