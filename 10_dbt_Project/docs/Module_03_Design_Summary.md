# Enterprise Staging Layer
## Module 03 - Design Summary

### Purpose of the Staging Layer
The `staging` layer acts as the foundation of the Medallion architecture (Silver). It is a 1:1 mapping to the `sources`. We never query raw sources directly in downstream models. If the raw table name or connection string changes, we update the staging model once, and all 50 downstream models inherit the fix seamlessly.

### Why Standardization Happens Here
Staging is strictly for **technical standardization**, not business logic.
- **Naming Conventions:** We enforce `snake_case` on all columns. The column `OrderID` in Shopify and `ORDER_ID` in Oracle ERP both become `order_id` in staging.
- **Data Typing:** We explicitly `CAST` all strings to defined types (e.g., `VARCHAR`, `TIMESTAMP_NTZ`, `NUMBER`).
- **Timezones:** We explicitly cast all timestamps to UTC.
- **Null Handling:** Empty strings `''` are cast to actual SQL `NULL`s.
- **Booleans:** "Y"/"N", "1"/"0", "True"/"False" are universally cast to `boolean`.

### Why NO Business Logic Belongs Here
We do not filter active vs inactive records, join tables, or calculate KPIs in staging.
- **Trade-off:** If we join `customers` and `orders` in staging, we lose the ability to analyze orphaned orders independently. Keeping staging 1:1 with sources maximizes reusability. Any analyst needing "raw but clean" data can query staging safely.

### Materialization Strategy
All staging models are materialized as `view`.
- **Trade-off:** Views do not consume physical storage or take time to build. Snowflake's query compiler pushes the logic of the view down into the underlying raw table scan when queried by downstream `marts`. Since staging models do no heavy lifting (just casting/renaming), materializing them as tables or incrementals adds unnecessary compute latency without performance benefit.
