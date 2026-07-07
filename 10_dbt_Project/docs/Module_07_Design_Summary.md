# Enterprise Incremental Models Framework
## Module 07 - Design Summary

### Why Incremental Models?
In a massive enterprise retail environment, tables like `TB_SALES_FACT` grow by millions of rows daily. Running a **Full Refresh** (dropping and rebuilding the entire table) requires Snowflake to scan terabytes of historical data, burning through FinOps budgets rapidly. **Incremental models** only process the *delta* (net-new or recently updated records), dropping Snowflake warehouse execution times from hours to seconds.

### Incremental Processing Strategies in Snowflake
dbt supports multiple strategies. Choosing the right one is critical for both data integrity and Snowflake performance:

1. **`append`**: The fastest strategy. Simply runs an `INSERT` statement. 
   - *Use Case:* Immutable, append-only streams like IoT sensor logs or raw server clicks. 
   - *Risk:* If run twice, it creates duplicates. Cannot handle late-arriving updates (e.g., an order changing from 'Pending' to 'Shipped').

2. **`merge`**: The standard enterprise default. Executes a Snowflake `MERGE` statement matching on a `unique_key`. If the key exists, it updates; if not, it inserts.
   - *Use Case:* Accumulating Snapshot facts (`fact_orders`) and highly mutating dimensions (`dim_customer`).
   - *Risk:* Requires a cluster key on the merge condition to prevent full table scans during the match phase.

3. **`insert_overwrite`**: The most performant strategy for massive data. Instead of evaluating row-by-row like `merge`, it drops an entire micro-partition (e.g., a specific Day) and inserts the newly calculated Day. 
   - *Use Case:* Heavy periodic snapshots (`fact_inventory_snapshot`) where an entire day's balance is recalculated.
   - *Requirement:* The table must be partitioned (clustered in Snowflake) strictly by the partition key.

### Watermark Integration & Late Arriving Data
We integrate with the CDC framework (Phase 8) by utilizing the `metadata_inserted_at` and `dbt_updated_at` timestamps. To capture Late Arriving Data securely, our incremental filters do not just look at "today"; they dynamically look back at `max(updated_at) - 3 days` (a sliding watermark) to catch any delayed upstream REST API payloads.
