# Enterprise Logging & Exception Framework
## Module 03 - Design Summary

### Logging Strategy
The logging strategy mandates **100% structured JSON logging**. In a cloud environment, plain text logs are difficult to parse and aggregate. Every log emitted by the framework is a JSON object containing standardized telemetry keys: `timestamp`, `level`, `pipeline_id`, `job_name`, `module`, and `message`.

### Centralized Logging
Logs are emitted to `stdout`/`stderr` allowing external orchestrators (AWS MWAA, Docker, Kubernetes) to seamlessly capture and forward them to a centralized observability platform like Datadog, Splunk, or CloudWatch via FluentBit. Additionally, critical **Audit** and **Performance** logs are synchronously written back to Snowflake metadata tables (e.g., `DB_PROD_METADATA.SC_META_CONTROL.TB_PIPELINE_LOG`) using the active Snowpark session.

### Structured Logging Classes
- **Pipeline Logger:** Emits standard INFO/ERROR messages detailing pipeline progression.
- **Audit Logger:** Emits specific JSON structures capturing Records Read, Records Written, execution time, and user context.
- **Performance Logger:** Emits granular metrics on CPU time, memory usage, and warehouse query execution times.
- **Business Event Logger:** Emits domain-specific events (e.g., "Customer LTV Recalculated").

### Exception Strategy & Error Categorization
Errors are not treated equally. The framework enforces a strict exception hierarchy to determine whether an orchestrator should retry or fail fast.
1. **RetryableExceptions:** Transient issues (e.g., `SnowflakeConnectionException`, `NetworkTimeoutException`). Handled by the `@retry_policy` decorator with exponential backoff.
2. **NonRetryableExceptions:** Permanent failures (e.g., `ConfigurationException`, `DataQualityException`, `SchemaValidationException`). The pipeline fails immediately to avoid wasting compute credits or corrupting data.
3. **PipelineExceptions:** Generic orchestration errors indicating a misconfigured DAG or state machine failure.
