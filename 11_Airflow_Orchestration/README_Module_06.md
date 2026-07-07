# Phase 11 - Module 6: Enterprise dbt Cloud Integration

This module seamlessly bridges Apache Airflow (the control plane) and dbt Cloud (the execution plane). By relying on dbt Cloud's highly optimized remote infrastructure to handle SQL compilation, we ensure our Airflow workers remain lightweight and decoupled from data processing.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `dbt_cloud/api` and `dags/dbt_cloud`.
- [x] **Custom API Client (`dbt_cloud_api_client.py`):** Extended the native DbtCloudHook to perform administrative tasks (cancelling stuck jobs) and pull crucial JSON artifacts (`run_results.json`) into Airflow for Data Quality parsing.
- [x] **Enterprise dbt Orchestration (`dbt_cloud_master_dag.py`):** An end-to-end DAG orchestrating the execution of Medallion transformations (`dbt build`), Type 2 SCDs (`dbt snapshot`), and documentation generation in logical sequence using the Deferrable architecture.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_06_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_06_Runbook.md).md) covering API Rate Limiting and strict Separation of Concerns.

## Usage Example (API Client)
```python
from dbt_cloud.api.dbt_cloud_api_client import EnterpriseDbtCloudClient

client = EnterpriseDbtCloudClient()
# After a job finishes, fetch the artifacts to parse row counts and test failures
run_results = client.fetch_run_results_artifact(run_id=123456)

print(f"Number of tests executed: {len(run_results['results'])}")
```
