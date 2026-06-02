# Interview Notes: Incremental Framework

## Q: When should you AVOID incremental models?
**A:** "Incremental models add significant logical complexity and risk of data drift. I avoid them when the underlying table is small (e.g., under 10 million rows in Snowflake). Rebuilding a 5-million-row dimension table as a `table` materialization takes less than 5 seconds in Snowflake. The compute saved by making it incremental is completely offset by the engineering time spent debugging watermark drift. I reserve incremental models strictly for massive Facts and multi-billion row logs."

## Q: How do incremental models integrate with Snowflake MERGE?
**A:** "When you set `incremental_strategy = 'merge'` in dbt, dbt compiles a native Snowflake `MERGE INTO target USING source ON target.id = source.id WHEN MATCHED THEN UPDATE WHEN NOT MATCHED THEN INSERT`. The critical architectural requirement here is Clustering. If the Snowflake table isn't clustered by the merge key (or a date key), Snowflake performs a Full Table Scan to find the matches, entirely defeating the performance benefit of the incremental load."

## Q: How do you handle schema changes in an incremental model?
**A:** "I use dbt's `on_schema_change: append_new_columns` configuration. This tells dbt that if I add a new metric to the SQL model, it should run an `ALTER TABLE ADD COLUMN` in Snowflake automatically before executing the incremental `MERGE`. However, if I rename a column, delete a column, or change a data type (e.g., `VARCHAR` to `NUMBER`), the incremental load will fail. In those destructive cases, a `--full-refresh` during a scheduled maintenance window is mandatory."

## Enterprise Best Practices Demonstrated
1. **Dynamic Lookbacks:** Writing reusable Jinja macros (`incremental_filter.sql`) to safely manage late-arriving data.
2. **Strategy Selection:** Explicitly selecting `insert_overwrite` for snapshot facts (Inventory) vs `merge` for transactional facts (Sales).
