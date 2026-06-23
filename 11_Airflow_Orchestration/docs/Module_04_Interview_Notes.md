# Interview Notes: Snowflake Operators & Hooks

## Q: How does Airflow communicate with Snowflake?
**A:** "Airflow uses the Snowflake Python Connector under the hood, wrapped inside the `SnowflakeHook`. The connection details (Account, User, Keypair) are managed securely in Airflow Connections. When a DAG runs, the Airflow worker establishes a TCP connection to Snowflake, submits the SQL query, and waits for a success/failure status code to be returned."

## Q: When do you execute SQL directly vs. calling a Stored Procedure?
**A:** "In Airflow, we prefer to execute raw SQL *only* for basic, atomic operations (e.g., triggering a Task, updating a watermark). If the logic requires complex looping, exception handling, or procedural logic (like flattening deeply nested JSON), we write a Snowpark Python Stored Procedure, deploy it to Snowflake, and simply use Airflow to `CALL` the procedure. This keeps Airflow stateless and pushes the heavy compute down to Snowflake."

## Q: Why build custom Operators instead of using the out-of-the-box SnowflakeOperator?
**A:** "In a massive enterprise, we have strict governance rules. We need to check if a CDC Stream is empty before spinning up an XLARGE warehouse. We need to explicitly wrap multi-statement SQL in `BEGIN/COMMIT` blocks. If we rely on Data Engineers to remember to do this every time they write a DAG, they will forget. By subclassing the `SnowflakeOperator` into `EnterpriseSnowflakeOperator`, we bake those compliance and cost-saving rules directly into the underlying Python class."

## Enterprise Best Practices Demonstrated
1. **DRY Principle in Python:** Abstracting DBA functions (like checking warehouse health) into a reusable Hook.
2. **Defensive Programming:** The Operator dynamically intercepts the execution flow to check `SYSTEM$STREAM_HAS_DATA`, preventing thousands of dollars of wasted compute on empty streams.
