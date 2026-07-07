# Operational Runbook: Incremental Framework

## Common Production Issues

### 1. Missed Updates (Incorrect Watermarks)
**Symptom:** An order's status was updated to 'Cancelled' in Shopify 3 days ago, but Power BI still shows it as 'Shipped'.
**Root Cause:** The `fact_orders` incremental model was configured to only look at `dbt_updated_at > current_date()`. Because the order was originally placed 4 days ago, the incremental filter ignored it, despite the recent status mutation.
**Resolution:** 
Never hardcode `current_date()` in an incremental filter. Always use the dynamic watermark: `where dbt_updated_at > (select max(dbt_updated_at) from {{ this }})`. If upstream systems do not have reliable update timestamps, utilize a sliding 3-day lookback window: `where dbt_updated_at >= dateadd(day, -3, current_date())`.

### 2. Schema Changes Breaking Incremental Loads
**Symptom:** `dbt run` fails with `column mismatch: destination table has 40 columns, view has 41`.
**Root Cause:** An Analytics Engineer added a new column (`is_b2b_sale`) to the `fact_sales_incremental` model, but dbt failed to insert it because the physical Snowflake table was already created with 40 columns.
**Resolution:**
In `dbt_project.yml`, configure `on_schema_change: append_new_columns`. If a column is dropped or its data type changes, a `--full-refresh` is mandatory to recreate the physical Snowflake table.

### 3. Duplicate Records During `insert_overwrite`
**Symptom:** `fact_inventory` shows double the stock quantities for January 15th.
**Root Cause:** The `insert_overwrite` strategy was used, but the `partitions` configuration did not correctly identify January 15th as the partition to drop before inserting the new data.
**Resolution:**
When using `insert_overwrite` in Snowflake, you must explicitly declare the `partitions` block in the dbt config, or rely on Snowflake's dynamic dynamic partition replacement. Ensure the source data does not contain multiple dates if you only intend to overwrite a single date partition.
