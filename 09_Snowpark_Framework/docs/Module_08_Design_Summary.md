# Enterprise Audit & Metadata Framework
## Module 08 - Design Summary

### Audit & Metadata Strategy
Data pipelines without operational metadata are a "black box." If a stakeholder asks, "Is the Sales dashboard accurate right now?", data engineers cannot confidently answer without querying Snowflake metadata. This framework centralizes all execution telemetry (rows read, rows written, error counts, latency) into unified Control Tables.
- **Operational Metadata:** Execution times, Warehouse sizes, Batch IDs, and Statuses.
- **Business Metadata:** Data Quality metrics, Reference Data fallback warnings, Quarantined row counts.
- **Technical/Schema Metadata:** Schema drift detection, data type changes.

### Data Lineage Strategy
Lineage is critical for Data Governance and impact analysis. Our `LineageTracker` establishes a directional, immutable graph of data movement.
We capture lineage across the entire stack:
`Source System (Shopify)` -> `Bronze (S3/Snowpipe)` -> `Silver (Snowpark/Tasks)` -> `Gold (dbt Models)` -> `Consumption (Power BI)`.
This allows us to execute proactive blast-radius analysis (e.g., "If I drop the `discount_code` column in Silver, which Power BI dashboards break?").

### Execution Tracking
We utilize Pydantic models (like `AuditManager` and `ExecutionTracker`) to tightly bind telemetry to the execution scope. Every Snowpark job initializes an `ExecutionTracker` at runtime, capturing `Start Time`, `Warehouse`, and `Pipeline Name`. Upon completion or failure, the tracker computes `Duration`, aggregates `Rows Rejected`, captures the `Query IDs` (for FinOps attribution), and synchronously commits this payload to the `DB_PROD_METADATA` schema.
