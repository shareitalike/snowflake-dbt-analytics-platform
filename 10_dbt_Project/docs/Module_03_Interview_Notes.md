# Interview Notes: Staging Layer

## Q: Why is there almost no business logic in staging?
**A:** "Staging is the foundation of the DAG. It should be as reusable as possible. If I apply a filter in staging (e.g., `WHERE status != 'CANCELLED'`), then I can never use that model to build a 'Cancelled Orders Report' downstream. By keeping staging 1:1 with the source and only applying technical standardizations (casting, renaming), I ensure that any downstream model can safely consume from staging without inheriting hidden biases."

## Q: Why rename columns here?
**A:** "To protect downstream code. If the upstream ERP changes a column name from `CUST_ID` to `CUSTOMER_IDENTIFIER`, I don't want to update 50 downstream fact tables. I update the alias once in `stg_erp__customers.sql` (`CUSTOMER_IDENTIFIER as customer_id`), and the rest of the warehouse is shielded from the schema drift."

## Q: Why not join tables in staging?
**A:** "Staging should represent atomic business entities. Joining tables violates the Single Responsibility Principle. If I join `Customers` and `Orders` in staging, I create a pre-aggregated model that is harder to debug and limits reusability. Joins belong in the `intermediate` or `marts` layers where explicit Kimball dimensional modeling takes place."

## Q: How do you handle duplicates?
**A:** "Duplicates are common in append-only CDC streams. I handle them defensively in staging using a window function or `dbt_utils.deduplicate`. We partition by the natural business key and order by the metadata ingestion timestamp, keeping only the latest record. This ensures the Gold layer is perfectly clean."

## Enterprise Best Practices Demonstrated
1. **Defensive Casting:** Explicitly casting all fields prevents implicit cast failures in Snowflake.
2. **Metadata Injection:** We preserve the `metadata_inserted_at` timestamp from the Snowpipe ingestion and add a `dbt_updated_at` timestamp in staging to track exact pipeline latency.
