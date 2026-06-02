# Enterprise Intermediate Layer
## Module 04 - Design Summary

### Purpose of the Intermediate Layer
While the `staging` layer standardizes data 1:1 against the raw source, the `intermediate` layer is where we construct our **business logic**. This layer bridges the gap between atomic source entities and the final aggregated dimensional models (`marts`). 
- We join entities (e.g., `orders` + `customers` + `payments`).
- We perform complex derivations (e.g., calculating Net GMV, Tax allocations).
- We resolve Business Keys into Surrogate Keys (via `dbt_utils.generate_surrogate_key`).

### Why Business Logic Belongs Here
If we embed complex tax calculations or currency conversions directly inside the final `fct_sales` model, that logic becomes trapped. If the Finance team asks for an `fct_refunds` model, we would have to copy-paste the tax logic. By isolating reusable business rules in the `intermediate` layer (e.g., `int_orders_enriched`), multiple downstream marts can select from it, adhering strictly to the **DRY (Don't Repeat Yourself)** principle.

### Materialization Strategy
By default, we configure `intermediate` models as **`ephemeral`**.
- **Ephemeral models** do not create physical views or tables in Snowflake. Instead, dbt compiles them as Common Table Expressions (CTEs) injected directly into the downstream Mart models. 
- **Trade-off & Exception:** If an intermediate model is referenced by 4 or more downstream marts, injecting a massive CTE 4 times will cause Snowflake compiler bloat ("Query too complex" errors). In these cases, we explicitly override the materialization to `table` or `view` to act as a physical checkpoint.
