# Enterprise Airflow Standards & Guidelines

To prevent the "Spaghetti DAG" phenomenon in a large enterprise, all Data Engineers must adhere to the following standards.

## 1. DAG Standards
- **Stateless Design:** Airflow Tasks must be idempotent. If a DAG fails halfway through and is retried, it must produce the exact same result as if it ran perfectly the first time (no duplicate data).
- **No Data Processing:** Airflow is an orchestrator, not an execution engine. You may NEVER pull a pandas DataFrame into an Airflow worker to transform it. Use `SnowflakeOperator` or `DbtCloudRunJobOperator` to push the compute down to the target systems.
- **Task Granularity:** A single task should do exactly one thing. Do not write a 500-line PythonOperator that downloads, transforms, and uploads data. Break it into `S3Sensor` -> `SnowflakeOperator`.

## 2. Naming Standards
- **DAG IDs:** Must be globally unique, lowercase, and snake_case. Prefix with the domain: `[domain]_[frequency]_[process]`.
  - *Example:* `sales_daily_revenue_load`
- **Task IDs:** Must explicitly describe the action.
  - *Example:* `trigger_dbt_marts_job` (Not `run_dbt`)
- **Connection IDs:** Must explicitly reference the environment.
  - *Example:* `snowflake_prod_svc`, `dbt_cloud_api_default`

## 3. Folder Standards
```text
11_Airflow_Orchestration/
├── dags/
│   ├── sales/           # Domain-driven DAG grouping
│   ├── supply_chain/
│   └── common/          # Shared sub-DAGs or TaskGroups
├── plugins/             # Custom Airflow UI plugins
├── operators/           # Custom OmniRetail Python operators
├── hooks/               # Custom system connection logic
├── sensors/             # Custom event listeners (e.g., S3 file arrival)
├── utils/               # Reusable Python helper functions (e.g., Slack alerts)
├── config/              # Airflow config files (airflow.cfg)
├── logs/                # Local log output for development
└── tests/               # Pytest suites for DAG integrity
```

## 4. Connection Strategy
Airflow connects to multiple heterogeneous systems. We enforce the following standard connections:
1. **`snowflake_default`:** Uses Key-Pair Authentication (not passwords) to connect to Snowflake via the `SnowflakeOperator`.
2. **`aws_default`:** Assumes an IAM Role to interact with S3 and Secrets Manager via `boto3`.
3. **`dbt_cloud_default`:** Uses a Service Account Token (not a personal user token) to interact with the dbt Cloud API.
4. **`slack_api_default`:** Webhook connection for the `on_failure_callback` alerting system.
