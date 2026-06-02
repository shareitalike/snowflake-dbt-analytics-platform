# Interview Notes: Fact Layer

## Q: What is a Fact Table Grain and why is it important?
**A:** "The grain is the fundamental definition of exactly what one row in the table represents. For example, `fct_sales` has a grain of 'One row per item sold per transaction'. Getting the grain wrong is the number one cause of data corruption in a warehouse because it inevitably leads to joining at different granularities, which causes fan-outs and double-counting of revenue."

## Q: How do you optimize large fact tables?
**A:** "In Snowflake, the two biggest performance levers are Incremental Processing and Clustering. 
1. I configure dbt fact models with `materialized='incremental'` using the `merge` strategy to process only the delta.
2. I apply `CLUSTER BY (Date_SK, Store_SK)`. Because Snowflake is a micro-partitioned columnar database, Clustering ensures that when a BI query asks for 'Last month's sales in New York', Snowflake skips 99% of the physical files and only scans the exact partitions containing that data."

## Q: Why do you separate `fct_orders` from `fct_sales`?
**A:** "Different business processes require different grains. `fct_orders` is an Accumulating Snapshot. It has one row per Order Header and tracks milestones (Order Placed, Order Shipped, Order Delivered). It answers questions like 'What is our average fulfillment latency?'. `fct_sales` is a Transaction Fact. It has one row per Line Item. It answers questions like 'Which specific product SKU generates the highest profit margin?'. Combining them forces a distorted grain."

## Enterprise Best Practices Demonstrated
1. **Strict Dimensional Alignment:** All keys in the fact table are `_SK` (Surrogate Keys) joining perfectly to the Module 5 dimensions. No natural business keys are used for joins.
2. **Defensive Coalescing:** Using `coalesce` to convert `NULL` metrics to `0` to prevent BI aggregations from breaking.
