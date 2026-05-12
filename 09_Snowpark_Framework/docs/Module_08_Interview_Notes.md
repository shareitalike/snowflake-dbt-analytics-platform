# Interview Notes: Audit & Metadata Framework

## Q: How do you implement audit logging in Snowpark?
**A:** "I use a unified `ExecutionTracker` that operates as a Context Manager. When a job starts, it captures the Warehouse, Start Time, and Batch ID. As the pipeline executes, the framework aggregates metrics like `Rows Read`, `Rows Written`, and `Quarantined Count`. When the job exits—either successfully or via an Exception—the context manager guarantees that a structured JSON payload is written to our central Control Table in Snowflake. This ensures we never lose telemetry, even on failures."

## Q: How do you track lineage?
**A:** "Lineage isn't just about dbt. Our `LineageTracker` spans the entire ecosystem. We track the `Source System` and `Landing Tables`, link them to Snowpark transformations via the `Pipeline_ID`, and bridge them to the Gold layer via dbt. This metadata is exposed to Data Stewards, allowing us to perform blast-radius analysis before making schema changes."

## Q: How do you troubleshoot failed pipelines using Metadata?
**A:** "Because our `AuditManager` captures the exact Snowflake `Query IDs`, `Error Count`, and `Execution Status`, troubleshooting is immediate. I don't need to dig through messy text logs. I query the Control Table for the failed `Run ID`, retrieve the exact Query ID that failed, and use Snowsight's Query Profile to see if it was a warehouse spill, a syntax error, or a timeout. The metadata tells the whole story."

## Enterprise Best Practices Demonstrated
1. **Context Management:** Using Python's `__enter__` and `__exit__` to guarantee audit closures.
2. **FinOps Attribution:** Capturing Warehouse sizing and Query IDs allows us to map Snowflake credit consumption directly to specific pipelines and business units.
3. **Immutability:** Audit records are insert-only. We never UPDATE a completed audit log.
