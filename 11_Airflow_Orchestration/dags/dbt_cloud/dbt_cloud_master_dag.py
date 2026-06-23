"""
==============================================================================
FILE: dbt_cloud_master_dag.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: A master orchestration DAG specifically designed to sequence the execution of dbt Cloud jobs (Build -> Snapshot -> Docs) and retrieve artifacts.
DESIGN DECISIONS: Uses Airflow's Taskflow API (@task) and XComs to dynamically pass the run_id from the dbt Build step into a custom Python function that fetches the run_results.json artifact.
WHY: Relying solely on dbt Cloud's internal scheduler creates a blind spot. Triggering dbt from Airflow allows you to pull the metadata (like test failures and row counts) out of the dbt API and log it centrally in Snowflake for data observability.

DAG ATTRIBUTES:
- Trigger Type: Event-Driven
- SLA: 2 hours
- Support Runbook: https://wiki.omniretail.com/data/runbooks/dbt-cloud-dag
==============================================================================
"""
from datetime import datetime
from airflow import DAG
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator
from airflow.operators.empty import EmptyOperator
from airflow.decorators import task
from dbt_cloud.api.dbt_cloud_api_client import EnterpriseDbtCloudClient
from callbacks.enterprise_callbacks import enterprise_failure_callback

default_args = {
    'owner': 'analytics_eng_team',
    'depends_on_past': False,
    'on_failure_callback': enterprise_failure_callback,
    'dbt_cloud_conn_id': 'dbt_cloud_default',
}

with DAG(
    'dbt_cloud_master_integration_dag',
    default_args=default_args,
    description='End-to-End dbt Cloud Execution and Artifact Retrieval.',
    schedule_interval=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['domain:core', 'dbt'],
) as dag:

    start = EmptyOperator(task_id='start')

    # 1. Trigger the main build dynamically based on Environment Variables
    # E.g., Dev uses 20001, Prod uses 10001
    dbt_build = DbtCloudRunJobOperator(
        task_id='run_dbt_build',
        job_id="{{ var.json.prod_variables.dbt_build_job_id }}", 
        check_interval=60,
        deferrable=True,
    )

    # 2. Run Snapshots (SCD Type 2 processing)
    dbt_snapshot = DbtCloudRunJobOperator(
        task_id='run_dbt_snapshot',
        job_id="{{ var.json.prod_variables.dbt_snapshot_job_id }}",
        check_interval=60,
        deferrable=True,
    )

    # 3. Generate Docs and Source Freshness
    dbt_docs = DbtCloudRunJobOperator(
        task_id='generate_dbt_docs',
        job_id="{{ var.json.prod_variables.dbt_docs_job_id }}", 
        check_interval=60,
        deferrable=True,
    )

    # 4. Pull Artifacts for metadata logging (Taskflow API)
    @task
    def extract_run_results(run_id: int):
        client = EnterpriseDbtCloudClient()
        results = client.fetch_run_results_artifact(run_id=run_id)
        # In a real environment, write `results` to a Snowflake logging table here
        return f"Parsed {len(results.get('results', []))} nodes."

    # Using XCom to pass the Run ID dynamically from the Build step
    extract_artifacts = extract_run_results(run_id=dbt_build.output)

    end = EmptyOperator(task_id='trigger_power_bi_refresh')

    # Lineage definition
    start >> dbt_build >> extract_artifacts >> dbt_snapshot >> dbt_docs >> end
