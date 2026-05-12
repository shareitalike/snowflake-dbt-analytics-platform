# Operational Runbook: Data Validation & Quarantine

## Common Production Issues

### 1. Unexpected Schema (Schema Drift)
**Symptom:** Pipeline fails at Pre-Flight with `SchemaValidationException: Missing required column 'discount_code'`.
**Root Cause:** Upstream engineering dropped or renamed a column in the Shopify source without notifying the Data team.
**Resolution:** 
1. If the drop was intentional, update the Pydantic/JSON schema definition in the framework to mark the column as optional or remove it.
2. If unintentional, notify upstream to fix the publisher. The pipeline will automatically recover on the next run once the source schema is corrected.

### 2. High Quarantine Volume (Null Business Keys)
**Symptom:** Pipeline succeeds, but 10,000 records are routed to the Quarantine table with reason `NULL_BUSINESS_KEY`.
**Root Cause:** A source system bug produced empty string `""` or `NULL` values for the Primary Key.
**Resolution:**
Data Stewards must query the quarantine table:
`SELECT * FROM DB_PROD_RAW.SC_QUARANTINE.TB_SHOPIFY_ORDERS_DLQ WHERE Pipeline_Run_ID = 'X';`
Once the source data is fixed in the operational system, it will be re-ingested. The DLQ rows can be purged manually or via a 30-day retention policy.

### 3. Duplicate Keys in Source
**Symptom:** Pipeline fails with `DataQualityException: Duplicate Primary Keys detected above threshold`.
**Root Cause:** The upstream CDC tool (e.g., Fivetran/Qlik) sent multiple identical inserts in the same batch.
**Resolution:** 
If the framework is configured to `fail_on_duplicates=True`, it halts. 
To bypass, configure the `QualityValidator` to `deduplicate_and_quarantine`, which will take the latest row using `QUALIFY ROW_NUMBER() OVER (PARTITION BY pk ORDER BY updated_at DESC) = 1` and push the dupes to DLQ.

### 4. Malformed JSON / Type Casting Errors
**Symptom:** Snowpark fails during `df.withColumn` casting with `Numeric value 'N/A' is not recognized`.
**Root Cause:** Upstream sent a string in a numeric field.
**Resolution:**
Modify the validation rules to use `TRY_CAST()` in Snowpark. Rows that yield `NULL` after a `TRY_CAST` should be routed to the DLQ instead of failing the entire query.
