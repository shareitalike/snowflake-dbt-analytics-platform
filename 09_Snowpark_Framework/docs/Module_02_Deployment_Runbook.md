# Operational Runbook: Snowpark Session Management

## Common Production Issues

### 1. Expired Credentials (HTTP 401/403)
**Symptom:** Pipeline fails immediately with `SnowparkClientException: Invalid credentials`.
**Root Cause:** The key-pair used for Snowflake authentication has expired, or the service account password was rotated without updating AWS Secrets Manager.
**Resolution:** 
1. Regenerate the RSA Key Pair or Password.
2. Update the secret in AWS Secrets Manager using the exact secret name defined in `prod.toml` (`snowflake/omni/prod_sa`).
3. Re-run the pipeline.

### 2. Session Timeout (Zombie Queries)
**Symptom:** Pipeline hangs for hours without logging progress, eventually terminating via the orchestration timeout (e.g., Airflow task timeout).
**Root Cause:** A complex DataFrame operation was compiled into a non-performant SQL query that exceeded the warehouse timeout, or the network connection dropped mid-execution.
**Resolution:**
1. Check Snowflake Query History to identify the hung query ID.
2. Abort the query via `SYSTEM$CANCEL_QUERY`.
3. Review the execution plan to see if a cross-join or unoptimized Python UDF caused the hang.
4. The `SnowparkSessionFactory` automatically closes connections if the Python process terminates, but orphan queries in Snowflake must be handled via warehouse-level `STATEMENT_TIMEOUT_IN_SECONDS`.

### 3. Network Failure / Transient Errors
**Symptom:** Intermittent `SnowparkConnectionException: Failed to connect to Snowflake` during peak usage.
**Root Cause:** Snowflake API throttling or transient DNS issues.
**Resolution:**
No manual intervention is required for transient errors. The framework's `tenacity` integration automatically retries connections 3 times with exponential backoff. If it fails after 3 retries, check Snowflake Status page.

### 4. Invalid Configuration
**Symptom:** `pydantic.error_wrappers.ValidationError: 1 validation error for SnowflakeConfig`.
**Root Cause:** A new environment variable was introduced in `dev.toml` but wasn't deployed to `prod.toml`, or the data type is incorrect (e.g., passing a string `"300"` instead of integer `300` for timeout).
**Resolution:** Update the TOML configuration to conform to the `ConfigLoader` Pydantic schema and redeploy.

### 5. Environment Mismatch
**Symptom:** Developer successfully runs pipeline locally, but it fails in QA.
**Root Cause:** The pipeline is trying to read from `DB_DEV_RAW` instead of `DB_QA_RAW`.
**Resolution:** Ensure that `ENVIRONMENT=qa` is explicitly set in the deployment manifest (e.g., Docker ENV var or Airflow variable). The `ConfigLoader` will then safely enforce the QA TOML definitions.
