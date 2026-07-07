# Enterprise JSON Processing Framework
## Module 06 - Design Summary

### Why Semi-Structured Data
Modern retail architectures rely heavily on SaaS integrations (Shopify, Zendesk, Stripe), Webhooks, and Event Streams (Kafka). These systems natively emit JSON. Attempting to force these dynamic payloads into rigid relational schemas upon ingestion leads to constant pipeline breakages.

### Why VARIANT
Snowflake's `VARIANT` data type allows us to ingest raw JSON exactly as it arrives without schema enforcement. Snowflake automatically optimizes the internal storage of `VARIANT` data into columnar structures, meaning querying `raw_payload:customer.id` is as fast as querying a dedicated integer column, provided the schema is relatively consistent.

### Why Snowpark
Parsing deeply nested JSON and arrays using raw SQL `LATERAL FLATTEN` becomes incredibly verbose and difficult to maintain. Snowpark allows us to build programmatic abstraction layers:
- We can recursively traverse keys.
- We can dynamically extract hundreds of fields without writing hundreds of `GET_PATH()` SQL statements.
- We can programmatically handle Schema Drift (new keys appearing in the JSON).

### Processing Strategy
1. **Extraction (Parser):** Dynamically extract scalar values from the `VARIANT` column using Snowpark dot-notation (`col("raw_payload")['customer']['email']`) and cast them to strict data types.
2. **Flattening:** Only use the `flatten()` table function when expanding Arrays (e.g., extracting `line_items` from an `Order` JSON). We minimize FLATTEN operations to avoid partition explosion.
3. **Schema Evolution:** The `SchemaDetector` allows for optional extraction. If a key is missing from the payload, Snowpark safely yields `NULL` instead of failing, supporting backward compatibility when third-party APIs change.
