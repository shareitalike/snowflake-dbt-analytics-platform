# Operational Runbook: Fact Layer

## Common Production Issues

### 1. Double Counting (Wrong Grain)
**Symptom:** The 'Gross Revenue' in Power BI is exactly 2x what it should be.
**Root Cause:** A developer joined `fct_sales` (Line Item grain) with a secondary event table (e.g., shipping milestones) that had multiple rows per line item.
**Resolution:** 
Never join Fact tables to other Fact tables in the database layer. All Fact tables must be joined only to Conformed Dimensions. In dbt, use the `dbt-expectations` package to assert that the `sum(revenue)` in the Fact matches the `sum(revenue)` in the Staging layer using `expect_column_sum_to_be_between`.

### 2. Missing Dimensions (Late Arriving Facts)
**Symptom:** Sales are missing from a specific Region report.
**Root Cause:** The `Store_SK` resolved to NULL because the Store dimension load failed upstream.
**Resolution:**
The Fact model must be defensive. We explicitly use `coalesce(store_sk, '-1')` when preparing the foreign keys in the intermediate layer. The `-1` joins to the `UNKNOWN` record we built into the Dimension tables in Module 5, ensuring the revenue is still captured and categorized as 'UNKNOWN' rather than dropped completely.

### 3. Slow Incremental Loads (Snowflake Full Table Scans)
**Symptom:** The daily incremental micro-batch takes 30+ minutes.
**Root Cause:** The `is_incremental()` macro is written as `where updated_at > (select max(updated_at) from {{ this }})`. This forces a full table scan on the destination Fact table to find the max date.
**Resolution:**
Ensure the Fact table is **Clustered** by the timestamp (e.g., `CLUSTER BY (date_sk)`). Snowflake will use its micro-partition metadata to find the `max(date)` in milliseconds instead of scanning terabytes of data.
