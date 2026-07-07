# Enterprise Dimension Models
## Module 05 - Design Summary

### Kimball Methodology & Conformed Dimensions
In the Gold layer, we transition strictly to Kimball Dimensional Modeling. 
- **Dimensions** are the "Who, What, Where, When, and Why" of a business process (Customers, Products, Stores, Dates).
- **Conformed Dimensions** are dimensions that are identical across all fact tables. `dim_date` is the classic example; whether you are querying `fct_sales` or `fct_inventory`, you join against the exact same `dim_date` table. This ensures the business has a "Single Source of Truth."

### Surrogate Keys vs Business Keys
- **Business Key:** The natural identifier from the source system (e.g., `Shopify_Customer_123`).
- **Surrogate Key:** An integer or hash (e.g., `md5(Shopify_Customer_123)`) generated in the data warehouse. 
- **Why Surrogate Keys?** 
  1. If two source systems (Shopify and Retail POS) both have a Customer ID `123`, they will collide. Surrogate keys ensure global uniqueness across the enterprise. 
  2. They are required to support Slowly Changing Dimensions (SCD Type 2), where the same Business Key might have multiple records over time (e.g., Customer moved from NY to CA).

### Materialization Strategy
By default, dimensional models are materialized as **`table`**.
- **Trade-off & Justification:** Dimensions are typically small compared to Facts (e.g., 5M customers vs 2B transactions). Rebuilding a dimension table fully on every run is fast and cheap. Trying to make dimensions `incremental` often introduces immense complexity for updates/deletes that costs more in engineering time than it saves in Snowflake compute credits.
- **Exception:** Massive dimensions (e.g., 500M user profiles) can be materialized incrementally, but this project will default to `table` for simplicity and performance. Slowly Changing Dimensions (SCD2) are handled natively by dbt `snapshots`, which we will implement in the configuration layer.
