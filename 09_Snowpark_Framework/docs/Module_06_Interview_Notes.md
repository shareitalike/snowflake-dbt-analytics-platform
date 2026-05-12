# Interview Notes: JSON & Semi-Structured Framework

## Q: How do you process nested JSON?
**A:** "In Snowpark, I use a combination of dot-notation extraction and casting. Instead of writing verbose `GET_PATH()` SQL, I built a `JSONParser` class that accepts a dictionary mapping (e.g., `{'customer_id': 'customer.id'}`). The parser programmatically iterates through this map, applies `col('payload')[path]`, and casts it to the correct type. This keeps the code DRY and highly readable."

## Q: When do you use FLATTEN?
**A:** "I use the `flatten()` table function exclusively when I need to explode a JSON Array into multiple rows—for example, turning one Shopify Order with 5 `line_items` into 5 distinct rows. I actively *avoid* flattening Objects, because I can extract object keys directly using path notation. Unnecessary flattening causes massive performance degradation due to partition explosion."

## Q: How do you support schema evolution in JSON?
**A:** "The beauty of the `VARIANT` column is that it inherently supports additive schema evolution. If a third-party API adds a new field, the ingestion pipeline doesn't break—the field just sits in the `VARIANT` payload. When the business is ready to use it, we simply add a mapping line to our `JSONParser` configuration. If a field is removed, Snowpark safely evaluates it as `NULL`, which we handle gracefully in our Validation layer."

## Q: Why use Snowpark instead of SQL for JSON?
**A:** "Maintainability. Extracting 100 fields from a highly nested JSON payload in SQL requires 100 lines of `CAST(GET_PATH(...) AS VARCHAR)`. In Snowpark, I define a Python dictionary mapping the JSON paths to the target columns, and a 5-line loop dynamically generates the AST for the entire extraction. It's infinitely easier to read, test, and update."

## Enterprise Best Practices Demonstrated
1. **Micro-Partition Pruning:** We extract business keys (like `tenant_id` or `updated_at`) as native columns alongside the `VARIANT` payload to allow Snowflake to prune partitions before scanning the JSON.
2. **Minimizing FLATTEN:** We avoid nested lateral joins which consume exponential compute credits.
3. **Safe Casting:** Using `cast()` in Snowpark ensures type safety downstream.
