# Operational Runbook: Logging & Exceptions

## Common Production Issues

### 1. Retry Storms
**Symptom:** A transient database lock causes multiple concurrent tasks to retry simultaneously, overwhelming the warehouse queue.
**Root Cause:** The `tenacity` retry decorator was misconfigured with a static wait time instead of exponential backoff with jitter.
**Resolution:** Ensure `retry.py` uses `wait_exponential_jitter`. Do not override retry mechanics in application code.

### 2. Lost Logs
**Symptom:** Pipeline failed but no logs appear in CloudWatch or Datadog.
**Root Cause:** The logging framework was configured to write to a local file inside an ephemeral container (ECS/Docker) instead of `stdout`.
**Resolution:** Ensure `JSONFormatter` is strictly bound to a `StreamHandler(sys.stdout)`. Do not use `FileHandler` in cloud deployments.

### 3. Duplicate Logs
**Symptom:** Every log line appears twice or exponentially more times in the central dashboard.
**Root Cause:** Python logger propagation (`logger.propagate = True`) is enabled while multiple handlers are attached to the root logger.
**Resolution:** The framework explicitly sets `propagate = False` on the `LoggerFactory`. Ensure developers are using `get_logger()` from the framework and not `logging.getLogger()` natively.

### 4. Unhandled Exceptions
**Symptom:** Python process exits with Code 1, but no "FAILED" audit log is written to the Snowflake metadata table.
**Root Cause:** A raw built-in exception (e.g., `KeyError`) bypassed the framework's exception boundary catch block.
**Resolution:** All Snowpark entrypoints must be wrapped in a global `try...except Exception as e` block that converts the raw exception to an `ApplicationException`, emits a `CRITICAL` log, writes to the Audit Logger, and safely exits.

### 5. Memory Errors during Logging
**Symptom:** Pipeline OOM (Out of Memory) kills.
**Root Cause:** A developer attempted to log a full Pandas/Snowpark DataFrame object (`logger.info(df.collect())`) which serialized 10 million rows into the log stream.
**Resolution:** The framework restricts DataFrame logging. Enforce `logger.info(f"Row count: {df.count()}")` or `.show(10)` limits.
