# Enterprise Snapshot Framework
## Module 08 - Design Summary

### Why dbt Snapshots?
In an enterprise retail data warehouse, tracking historical state is paramount. If a Customer moves from "New York" to "California," we cannot simply overwrite their profile. If we do, all historical sales from when they lived in New York will suddenly report as California revenue. 
dbt Snapshots natively implement **Slowly Changing Dimensions (SCD Type 2)**. They automatically detect mutations in the source data and generate `dbt_valid_from` and `dbt_valid_to` columns, preserving the exact state of the dimension at any point in time.

### Snapshot Strategies
1. **Timestamp Strategy:** The preferred, high-performance strategy. dbt looks at an `updated_at` column in the source data. If the timestamp has advanced since the last snapshot run, dbt invalidates the old record (sets `dbt_valid_to` = current timestamp) and inserts the new record.
2. **Check Strategy:** The fallback strategy when upstream systems do not provide a reliable `updated_at` timestamp. dbt must compare a list of specified columns (e.g., `check_cols=['segment', 'email']`) row-by-row against the Snowflake table to detect if the data has mutated.

### Hard Deletes
By default, if a record is deleted from the source system, dbt snapshots ignore it (leaving the last known state active forever). By configuring `invalidate_hard_deletes=True`, dbt will detect that the primary key is missing from the source and will proactively set the `dbt_valid_to` timestamp on the historical record, marking it as deleted.

### Integration with the Pipeline
Snapshots are taken against the **Raw** or **Staging** layer. The output of the snapshot (`snap_customer`) is then consumed by the Intermediate layer, which utilizes `dbt_utils.generate_surrogate_key` to map the `dbt_scd_id` into a true dimensional `customer_sk`. This allows Fact tables to join precisely to the historical state of the dimension at the time the transaction occurred.
