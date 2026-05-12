# Interview Notes: Logging & Exception Framework

## Q: How do you implement centralized logging?
**A:** "In a cloud-native Snowpark deployment, logs must be strictly decoupled from the execution environment. I built a `LoggerFactory` that emits 100% structured JSON logs to `stdout`. This allows the orchestration layer (like MWAA or Kubernetes) to easily scrape and forward logs to Datadog/Splunk. For critical audibility—like data lineage and row counts—I implemented an `AuditLogger` that also executes synchronous `MERGE` statements back into Snowflake's `TB_PIPELINE_LOG` control tables using the active Snowpark session."

## Q: How do you classify exceptions?
**A:** "I use a strict hierarchy rooted in `ApplicationException`, split into two main branches: `RetryableException` and `NonRetryableException`. 
A `DataQualityException` (e.g., a null where one shouldn't be) is a `NonRetryableException`—retrying it will just waste Snowflake credits. 
Conversely, a `SnowflakeConnectionException` is a `RetryableException`. This classification dictates how the orchestration layer handles the failure."

## Q: How do you retry transient failures?
**A:** "I don't write custom while-loops. I implemented a `RetryFramework` utilizing the Python `tenacity` library. It uses a `@with_retry` decorator configured with `wait_exponential_jitter`. If a `RetryableException` is caught, it backs off exponentially (2s, 4s, 8s...) while adding random jitter to prevent 'thundering herd' retry storms against the Snowflake API."

## Q: How do you audit Snowpark jobs?
**A:** "Auditing isn't just about printing 'Job Started'. I created an `AuditContext` model that explicitly tracks `Pipeline_ID`, `Batch_ID`, `Records_Read`, `Records_Written`, and `Execution_Time`. Before a Snowpark job finishes, it passes this context to the `AuditLogger`, which persists it immutably into the metadata schema. This provides absolute lineage and observability for FinOps and Data Governance."

## Enterprise Best Practices Demonstrated
1. **Structured JSON Logging:** Prevents complex regex parsing in downstream observability tools.
2. **Exponential Backoff with Jitter:** The only enterprise-approved way to handle transient network issues safely.
3. **Fail-Fast Mechanics:** Immediate termination on Data Quality / Schema errors saves compute costs.
4. **Separation of Concerns:** Business logic doesn't know *how* to format an audit log; it just calls `AuditLogger.log_batch_complete(context)`.
