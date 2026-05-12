# Interview Notes: Data Validation Framework

## Q: How do you validate incoming data using Snowpark?
**A:** "I use a multi-tiered approach. First, I perform strict Schema Validation by inspecting the Snowpark DataFrame's `.schema` property against our expected schema definition before triggering any compute. If the schema passes, I apply declarative Data Quality rules using Snowpark Column expressions (like checking `col.is_null()`). Because Snowpark is lazy-evaluated, I chain all these validation rules into a single Snowflake query, avoiding expensive loop-based row-by-row checks."

## Q: How do you quarantine bad records?
**A:** "Instead of failing the entire batch for a few bad rows, I implement a Dead Letter Queue (DLQ) pattern. Using Snowpark, I split the DataFrame into two streams based on the validation boolean conditions. The 'clean' DataFrame proceeds to the core transformations. The 'dirty' DataFrame has a `rejection_reason` literal column appended and is written to a dedicated Quarantine schema (e.g., `DB_PROD_RAW.SC_QUARANTINE.TB_ORDERS_DLQ`) for Data Stewards to triage."

## Q: How do you support schema evolution?
**A:** "Our Schema Validator is strict on destructive changes but permissive on additive changes. If a source adds a new column, the validator logs a warning but allows the pipeline to proceed, automatically ignoring the unmapped column during the Silver load. If a source drops a required column or changes a string to an integer, it throws a `SchemaValidationException` and fails fast, preventing data corruption."

## Q: How do you measure data quality?
**A:** "Every time the `QualityValidator` runs, it generates a `ValidationReport` object containing metrics like `total_rows`, `failed_rows`, and `null_counts`. This report is injected into our `AuditLogger` (from Module 3) which writes it directly to our Snowflake Metadata control tables. This allows us to build a Data Quality Dashboard in Snowsight or Tableau to track degradation over time."

## Enterprise Best Practices Demonstrated
1. **Lazy Evaluation for DQ:** Chaining checks in Snowpark compiles to a highly parallelized Snowflake query.
2. **Dead Letter Queues:** Ensuring 99% of good data flows while isolating the 1% of bad data.
3. **Fail-Fast:** Catching schema drifts in milliseconds via metadata properties before reading TBs of data.
