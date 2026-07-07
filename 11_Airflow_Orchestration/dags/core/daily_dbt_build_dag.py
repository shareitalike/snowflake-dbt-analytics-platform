"""
ENTERPRISE DAG: Daily dbt Cloud Build

DAG Purpose: Triggers the master dbt Cloud Medallion architecture compilation.
Trigger Type: Triggered (via TriggerDagRunOperator from Master DAG).
Upstream Dependencies: ALL Bronze and Silver Airflow DAGs.
Downstream Dependencies: Power BI Executive Dashboards.
SLA: 3 hours.
Retry Policy: 1 retry, 10 minute delay.
Failure Notification Flow: PagerDuty (Sev 1), Slack #alerts-data-eng.
Estimated Runtime: 1.5 hours.
Business Owner: Chief Financial Officer (CFO).
Support Runbook: https://wiki.omniretail.com/data/runbooks/dbt-build-failure
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
