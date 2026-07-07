"""
ENTERPRISE DAG: dbt Cloud Master Integration

DAG Purpose: Orchestrates a massive dbt Medallion execution in logical steps (Build -> Snapshot -> Docs).
Trigger Type: Event-Driven (Triggered by Upstream Bronze/Silver pipelines completion).
Upstream Dependencies: enterprise_orchestration_dag.
Downstream Dependencies: Power BI, Data Observability Platform.
SLA: 2 hours.
Retry Policy: Handled at the dbt Cloud Job level.
Failure Notification Flow: Slack #alerts-dbt-failures (via enterprise callback).
Estimated Runtime: 45 minutes.
Business Owner: Analytics Engineering Lead.
Support Runbook: https://wiki.omniretail.com/data/runbooks/dbt-cloud-dag
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
