"""
ENTERPRISE DAG: Master Orchestration DAG

DAG Purpose: The apex orchestrator. Controls the exact topological execution order of the entire data platform to prevent circular dependencies.
Trigger Type: Scheduled (0 2 * * * -> 2:00 AM Daily).
Upstream Dependencies: N/A.
Downstream Dependencies: customer_ingestion_dag, inventory_pipeline_dag, daily_dbt_build_dag.
SLA: 6 hours (Overall Platform SLA).
Retry Policy: 0 retries (Retries handled by child DAGs).
Failure Notification Flow: PagerDuty (Sev 1).
Estimated Runtime: 3 hours.
Business Owner: CDO (Chief Data Officer).
Support Runbook: https://wiki.omniretail.com/data/runbooks/master-dag
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'platform_architecture_team',
    'depends_on_past': True,
    'retries': 0,
    'sla': timedelta(hours=6),
}

with DAG(
    'enterprise_orchestration_dag',
    default_args=default_args,
    description='The Master DAG controlling Bronze -> Silver -> Gold execution.',
    schedule_interval='0 2 * * *', 
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['master', 'tier:0'],
) as dag:

    start = EmptyOperator(task_id='kickoff_platform_build')

    trigger_customer_bronze = TriggerDagRunOperator(
        task_id='trigger_customer_bronze',
        trigger_dag_id='customer_ingestion_dag',
        wait_for_completion=True,
    )
    
    trigger_inventory_silver = TriggerDagRunOperator(
        task_id='trigger_inventory_silver',
        trigger_dag_id='inventory_pipeline_dag',
        wait_for_completion=True,
    )

    trigger_dbt_gold = TriggerDagRunOperator(
        task_id='trigger_dbt_gold',
        trigger_dag_id='daily_dbt_build_dag',
        wait_for_completion=True,
    )

    platform_ready = EmptyOperator(task_id='platform_ready_for_power_bi')

    start >> [trigger_customer_bronze, trigger_inventory_silver] >> trigger_dbt_gold >> platform_ready
