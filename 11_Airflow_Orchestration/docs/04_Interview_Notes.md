# Interview Notes: Enterprise Airflow

## Q: Why Airflow?
**A:** "In a modern enterprise, data doesn't live in just one system. We have AWS S3 for storage, Snowflake for compute, dbt Cloud for transformations, and Slack for alerting. We need a 'Control Plane' to manage these heterogeneous systems. Airflow is the industry standard because it allows us to define DAGs (Directed Acyclic Graphs) as Python code. This means we can unit test our orchestration, version control it in GitHub, and build dynamic pipelines that simply aren't possible with basic cron jobs."

## Q: Why not only use Snowflake Tasks?
**A:** "Snowflake Tasks are fantastic for purely internal operations, like running a `MERGE` statement every time a Snowflake Stream detects new data. But Snowflake Tasks cannot easily wait for a file to arrive in AWS S3, nor can they trigger a dbt Cloud Job via REST API, nor can they send a formatted error stack trace to Slack. Snowflake Tasks execute data; Airflow orchestrates systems."

## Q: Why not only use dbt Jobs?
**A:** "dbt Cloud Jobs are great for scheduling dbt models. But dbt is completely blind to what happens *before* the data gets to the Staging layer. If Fivetran fails to extract data from Salesforce, the dbt Job will run anyway, processing stale data and pushing incorrect metrics to Power BI. Airflow solves this by orchestrating the *entire* pipeline: it triggers Fivetran, waits for completion, triggers Snowflake validations, and *only then* triggers the dbt Job."

## Q: How do Airflow and Snowflake complement each other?
**A:** "It's the separation of Orchestration and Compute. Airflow is the brain; Snowflake is the muscle. We never process data inside Airflow workers (that causes out-of-memory crashes). Instead, Airflow uses the `SnowflakeOperator` to submit SQL queries to Snowflake. Snowflake uses its massively parallel compute to process the data, and returns a 'Success' signal back to Airflow."

## Enterprise Best Practices Demonstrated
1. **Stateless Idempotency:** Designing DAGs so they can be rerun at any time without duplicating data.
2. **Secrets Management:** Using AWS Secrets Manager as the Airflow backend to prevent hardcoding Snowflake passwords.
3. **Deferrable Operators:** Demonstrating advanced knowledge of Airflow Async operators to save compute costs when waiting for long-running Snowflake queries.
