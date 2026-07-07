# Operational Runbook: Intermediate Layer

## Common Production Issues

### 1. Duplicate Joins (Cartesian Explosions)
**Symptom:** A `stg_orders` table with 1M rows joins to `stg_customers`, and the resulting `int_orders_enriched` table outputs 2.5M rows. 
**Root Cause:** A one-to-many relationship was improperly handled, usually because a customer has multiple addresses or profiles in the source system.
**Resolution:** 
Always enforce a strict 1:1 grain when enriching fact tables. If joining to a customer profile, either `GROUP BY` the customer to get the latest profile, or use a window function (`row_number() over (partition by customer_id)`) to force uniqueness *before* joining to the order table. Validate this using a `unique` dbt test on the `order_id` in the intermediate model's `schema.yml`.

### 2. Slow Compilation (Ephemeral Bloat)
**Symptom:** `dbt build` takes 15 minutes in the "compiling" phase before sending any queries to Snowflake.
**Root Cause:** Heavy use of `ephemeral` materializations in models that reference *other* `ephemeral` models, creating deeply nested CTEs.
**Resolution:**
Materialize high-traffic intermediate models as `table` or `view`. Checkpoints break the dependency graph into manageable chunks for the Snowflake compiler.

### 3. Circular Dependencies
**Symptom:** `dbt run` immediately fails with `Found a circular dependency`.
**Root Cause:** `int_customers_enriched` `ref()`s `int_orders_summary`, but `int_orders_summary` `ref()`s `int_customers_enriched`.
**Resolution:**
Analytics Engineering requires strict Directed Acyclic Graphs (DAGs). Data must flow left to right. Resolve the loop by splitting the shared logic into a lower-level base model (e.g., `int_customer_order_base`).
