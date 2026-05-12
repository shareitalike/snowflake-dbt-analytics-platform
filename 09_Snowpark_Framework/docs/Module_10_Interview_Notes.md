# Interview Notes: End-to-End Architecture

## Q: Walk me through your Snowpark pipeline.
**A:** "Our Snowpark pipeline isn't just a script; it's an orchestrated state machine. It starts by securely bootstrapping the session and injecting an Audit Context Manager. It reads raw JSON (often landing from CDC streams), parses it natively using our JSON Parser without SQL explosion, and passes the dataframe through a strict, lazy-evaluated Data Quality and Business Rule engine. Clean records flow into the Temporal Reference Lookup engine for Surrogate Key resolution, while invalid records are cleanly sliced into a DLQ. Finally, the orchestrator writes the data to the Silver layer, flushes FinOps and DQ metrics to our Metadata schema, and terminates."

## Q: How does Snowpark integrate with CDC?
**A:** "In Phase 08, we built the Enterprise Streams and Tasks Framework. The CDC data lands in Snowflake as `APPEND_ONLY` raw tables or Streams. The Snowpark `PipelineOrchestrator` consumes from these Streams. Because Snowpark operates directly inside the Snowflake compute plane, we don't extract the CDC payload out to an external Spark cluster; we process the deltas in-place, yielding massive performance gains."

## Q: How do you handle failures?
**A:** "We classify failures strictly (Module 3). If it's a `RetryableException` (like a network timeout), our `@enterprise_retry_policy` handles exponential backoff. If it's a data anomaly (like a null business key), we don't fail the pipeline; we use DataFrame splitting to route the bad records to a Quarantine table (DLQ). If it's a catastrophic `NonRetryableException` (like a dropped schema), the Audit Context Manager traps it, logs the failure state and exact Query IDs to the Control Table, and fails fast."

## Q: How does Snowpark integrate with dbt?
**A:** "Snowpark owns the Bronze-to-Silver lifecycle—parsing JSON, enforcing complex business rules, calling external APIs via UDFs, and ML scoring. Once Snowpark writes to the Silver tables and flushes its metadata, an external orchestrator (like Airflow) triggers dbt. dbt then owns the Silver-to-Gold lifecycle, doing what it does best: declarative SQL aggregations, dimensional modeling, and ephemeral materialized views."

## Enterprise Best Practices Demonstrated
1. **Decoupled Architecture:** Merging Python's imperative strengths (JSON, ML, DLQ) with SQL's declarative strengths (dbt aggregations).
2. **Defensive Data Engineering:** Treating data pipelines like mission-critical software with DLQs, bounded lookups, and context managers.
