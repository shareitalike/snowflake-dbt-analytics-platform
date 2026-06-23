# Enterprise Snowflake Operators & Hooks
## Module 04 - Design Summary

### Why Custom Airflow Operators?
The native `SnowflakeOperator` is fantastic for running raw SQL. However, at OmniRetail scale, simply executing SQL is dangerous. We need conditional execution, pre-flight checks, and strict transaction handling. By inheriting from `SnowflakeOperator` and creating the `EnterpriseSnowflakeOperator`, we inject global business rules into every single task in our platform without requiring Data Engineers to write boilerplate Python.

### Why Custom Hooks?
An Operator defines *what* Airflow should do (e.g., execute a Stored Procedure). A Hook defines *how* Airflow talks to the external system.
We built the `EnterpriseSnowflakeHook` to abstract common DBA operations out of the DAG files. Instead of a Data Engineer writing raw SQL to check if a warehouse is suspended, they simply call `hook.validate_warehouse_health()`.

### Error Handling & Transaction Strategy
- **Explicit Transactions:** If `autocommit=False` is passed to the `EnterpriseSnowflakeOperator`, it dynamically wraps the SQL payload in a `BEGIN;` and `COMMIT;` block.
- **Rollback:** If an exception is caught mid-execution, the Operator catches it, executes an explicit `ROLLBACK;` via the Hook, and then re-raises the error to fail the Airflow task, ensuring no partial data is committed.

### Stream Validation
In our CDC architecture (Phase 08), Snowflake Tasks process Streams. If a Stream is empty, executing a massive `MERGE` statement wastes compute credits. The `EnterpriseSnowflakeOperator` natively checks `SYSTEM$STREAM_HAS_DATA` before running the SQL, returning a `SKIPPED` status if no data exists, instantly saving money.
