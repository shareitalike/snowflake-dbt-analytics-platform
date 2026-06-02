# Interview Notes: Snapshot Framework

## Q: What is SCD Type 2 and why is it important?
**A:** "Slowly Changing Dimension Type 2 is a data modeling technique used to track historical data over time. If a product's category changes from 'Electronics' to 'Clearance', we need to know exactly *when* that happened. SCD2 creates multiple records for the same Business Key, distinguished by effective dates (`valid_from`, `valid_to`). This ensures that sales made *before* the change are attributed to 'Electronics', and sales *after* are attributed to 'Clearance'. It preserves the historical truth of the data."

## Q: Why use dbt snapshots instead of building SCD2 logic manually?
**A:** "Writing MERGE statements to manage SCD2 logic (handling inserts, expiring old rows, managing boundary timestamps, and handling hard deletes) is notoriously complex and error-prone. dbt abstracts this entire process. We simply configure a block identifying the unique key and the update mechanism, and dbt compiles and executes the perfect Snowflake SCD2 MERGE statement on our behalf."

## Q: When should you use Timestamp vs Check strategy?
**A:** "I default to the **Timestamp Strategy**. It is drastically faster and cheaper in Snowflake because dbt only has to evaluate rows where `updated_at > max(dbt_valid_from)`. 
However, I will use the **Check Strategy** if:
1. The upstream source system is unreliable and doesn't provide a trustworthy `updated_at` column.
2. The `updated_at` column mutates too frequently for non-analytical reasons (e.g., 'last_login_date'), which would cause massive snapshot bloat. `check_cols` allows me to surgically track only the columns the business actually cares about."

## Enterprise Best Practices Demonstrated
1. **Invalidate Hard Deletes:** Explicitly setting `invalidate_hard_deletes=True` to prevent deleted source records from remaining 'active' indefinitely in the warehouse.
2. **Snapshotting upstream of the dimensional model:** Running snapshots against `stg_` models, allowing the `int_` and `dim_` layers to consume the raw `dbt_valid_from` timestamps to generate true historical Surrogate Keys.
