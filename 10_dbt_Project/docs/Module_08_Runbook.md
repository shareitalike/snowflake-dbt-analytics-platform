# Operational Runbook: Snapshot Framework

## Common Production Issues

### 1. Snapshot Bloat (Over-tracking)
**Symptom:** `snap_customer` grows from 5 million to 500 million rows in two weeks. Snowflake storage and compute costs skyrocket.
**Root Cause:** The `timestamp` strategy is being triggered by a volatile column that isn't analytically relevant (e.g., an `updated_at` timestamp that changes every time a user logs in, even if their profile data didn't change).
**Resolution:** 
Switch from the `timestamp` strategy to the `check` strategy. Explicitly declare `check_cols=['first_name', 'last_name', 'address', 'customer_segment']`. This forces dbt to only create a new historical row if an *analytically significant* attribute mutates.

### 2. Duplicate Business Keys
**Symptom:** The snapshot run fails with `Unique Key collision`.
**Root Cause:** The source table contains multiple rows for the same `unique_key` (e.g., a customer made two updates in the same day, and both rows were pulled into the Staging layer).
**Resolution:**
Snapshots *must* be run against a deduplicated source. Ensure the Staging layer uses `dbt_utils.deduplicate` (as implemented in Phase 10 - Module 3) before feeding data into the Snapshot engine.

### 3. Missing Historical Records
**Symptom:** A customer changed their tier from 'Active' to 'VIP', but the snapshot only shows the 'VIP' state.
**Root Cause:** The snapshot job is scheduled to run weekly. The customer mutated twice in that week ('Active' -> 'Occasional' -> 'VIP'). Because dbt snapshots operate on the current state of the source table at the time of execution, intermediate mutations between runs are lost.
**Resolution:**
Snapshots must be scheduled frequently enough to capture the business cycle. In our architecture, Snapshots are triggered as part of the hourly CDC micro-batch. To capture intra-hour mutations, you must bypass dbt snapshots and build a custom SCD2 engine using Snowflake Streams directly on the raw append-only logs.
