"""
==============================================================================
FILE: daily_dbt_build_dag.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: A core orchestration DAG responsible for triggering the master dbt Cloud Medallion architecture compilation job.
DESIGN DECISIONS: Uses the DbtCloudRunJobOperator with deferrable=True to trigger the remote dbt Cloud job without blocking an Airflow worker slot while waiting for completion.
WHY: Deferrable operators (Async) drastically reduce infrastructure costs. Instead of holding a Celery worker open for 2 hours while dbt runs, the worker is released, and a lightweight Triggerer polls the API asynchronously.

DAG ATTRIBUTES:
- SLA: 3 hours
- Retry Policy: 1 retry, 10 minute delay
- Notification Flow: PagerDuty (Sev 1), Slack #alerts-data-eng
==============================================================================
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'analytics_eng_team',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=10),
    'dbt_cloud_conn_id': 'dbt_cloud_default',
    'sla': timedelta(hours=3),
}

with DAG(
    'daily_dbt_build_dag',
    default_args=default_args,
    description='Triggers the main dbt Cloud Medallion build job.',
    schedule_interval=None, 
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['domain:core', 'tier:1', 'phase:dbt'],
) as dag:

    start = EmptyOperator(task_id='start')

    trigger_dbt_cloud_job = DbtCloudRunJobOperator(
        task_id='trigger_dbt_cloud_job',
        job_id=12345,
        check_interval=60,
        timeout=7200, # 2 hours timeout
        deferrable=True, 
    )

    end = EmptyOperator(task_id='end')

    start >> trigger_dbt_cloud_job >> end
