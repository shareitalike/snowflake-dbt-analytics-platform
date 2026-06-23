# Operational Runbook: Custom Snowflake Operators

## Common Production Issues

### 1. SQL Compilation Error vs. Execution Error
**Symptom:** Airflow task fails in 3 seconds with `SQL compilation error`.
**Root Cause:** Usually a missing Role permission or a syntax error in the Jinja-templated SQL.
**Resolution:** 
Check the Airflow logs. The `EnterpriseSnowflakeOperator` will print the *rendered* SQL before executing. Copy that rendered SQL into the Snowflake UI and attempt to run it using the Airflow Service Account role to debug.

### 2. Warehouse Suspended / Timeout
**Symptom:** Task fails with `Warehouse is suspended`.
**Root Cause:** The native Snowflake connection attempted to execute a query on a warehouse that auto-suspended, and the query timed out before the warehouse could resume.
**Resolution:**
Ensure the Airflow task is using `EnterpriseSnowflakeOperator` and pass `require_warehouse_resume=True`. The Operator will proactively issue an `ALTER WAREHOUSE RESUME` before submitting the heavy query.

### 3. Warehouse Credit Exhaustion
**Symptom:** `Warehouse credits exceeded limit`.
**Root Cause:** A poorly optimized Cartesian Join caused a Snowflake warehouse to scale up and consume massive credits over a weekend.
**Resolution:**
The `EnterpriseSnowflakeHook.monitor_warehouse_credits` function is designed to catch this. If the threshold is breached, it throws an alert to Slack. To fix, immediately suspend the warehouse via the Snowflake UI, terminate the rogue query, and enforce cluster keys on the underlying tables.
