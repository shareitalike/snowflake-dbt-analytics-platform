# Operational Runbook: JSON & Semi-Structured Data

## Common Production Issues

### 1. Performance Bottleneck on FLATTEN
**Symptom:** Pipeline processing Shopify Orders takes 45 minutes instead of 2 minutes.
**Root Cause:** A developer used nested `LATERAL FLATTEN` on an array of `orders` containing an array of `line_items` containing an array of `tax_lines`. This causes a Cartesian explosion of rows in memory.
**Resolution:** 
1. Use the `Flattener.flatten_array()` method specifically on the target array level. 
2. If multiple levels of arrays must be extracted, execute them in sequential DataFrame operations rather than a single massive join, or use `TRY_PARSE_JSON` strategically.

### 2. Schema Drift (Missing Fields)
**Symptom:** Pipeline fails with `AttributeError` or `SnowparkSQLException` when attempting to cast a missing JSON key.
**Root Cause:** An upstream API (e.g. Zendesk) stopped sending an optional field in their webhook.
**Resolution:**
The `JSONParser` uses safe extraction. Ensure that the business rule validation (Module 4) is configured to handle `NULL` gracefully for optional JSON attributes. If it's a required attribute, it will correctly route to the DLQ.

### 3. Deeply Nested JSON (Memory Errors)
**Symptom:** Out Of Memory (OOM) on the virtual warehouse when querying a 5MB JSON cell.
**Root Cause:** A single `VARIANT` cell exceeds the 16MB compressed limit (or is extremely dense), causing memory spills to remote storage during extraction.
**Resolution:** 
1. Scale up the warehouse to `LARGE` or `XLARGE` to get more memory per node.
2. Consider splitting the JSON upstream (e.g., AWS Lambda or API Gateway) before it lands in Snowflake.

### 4. Malformed Documents
**Symptom:** JSON parsing fails at the Bronze layer.
**Root Cause:** The source file (e.g., S3 export) contains invalid JSON (missing quotes, trailing commas).
**Resolution:**
Since this framework operates on the Silver layer (where data is already in a `VARIANT` column), malformed JSON is handled by the `COPY INTO` command at the Bronze layer using `ON_ERROR = CONTINUE`. Ensure the Snowpipe configuration is correct.
