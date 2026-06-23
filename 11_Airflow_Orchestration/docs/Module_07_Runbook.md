# Operational Runbook: Dynamic DAGs & TaskGroups

## Common Production Issues

### 1. Large DAG Parsing Time (Scheduler Lag)
**Symptom:** Airflow scheduler CPU hits 100%. DAGs are slow to trigger.
**Root Cause:** The `dag_factory.py` file is doing heavy compute (e.g., querying Snowflake or making API calls) at the top level. The Airflow Scheduler parses every Python file in the `dags/` folder every 30 seconds. If a file takes 5 seconds to parse, the scheduler grinds to a halt.
**Resolution:**
Top-level Python code must be lightning fast. Our `dag_factory.py` only reads a local YAML file. Never put database connections or API calls in the top level of a DAG file.

### 2. Configuration Drift
**Symptom:** A table was added in Snowflake, but the Airflow DAG isn't processing it.
**Root Cause:** The DBA added a stream in Snowflake but forgot to update the Airflow `domain_config.yaml`.
**Resolution:**
Move toward Metadata-Driven architecture where the `dag_factory.py` reads a JSON configuration generated directly by the dbt Cloud compilation process, ensuring Airflow is always in perfect sync with the data warehouse structure.

### 3. Circular TaskGroups
**Symptom:** DAG fails to render with `Cycle detected`.
**Root Cause:** The bitshift operators (`>>`) within a loop wired a downstream task back to an upstream task.
**Resolution:**
Use dummy `start` and `end` operators as anchors. Wire the dynamic TaskGroups explicitly: `start >> task_group >> end`.
