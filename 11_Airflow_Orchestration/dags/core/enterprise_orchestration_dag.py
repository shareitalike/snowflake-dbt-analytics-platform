"""
==============================================================================
FILE: enterprise_orchestration_dag.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: The apex controller DAG that dictates the precise topological execution order of all sub-DAGs (Bronze, Silver, Gold).
DESIGN DECISIONS: Utilizes TriggerDagRunOperator with wait_for_completion=True to synchronously trigger domain-specific DAGs (Customer, Inventory) before triggering the global dbt DAG.
WHY: Decoupling complex pipelines into modular sub-DAGs makes the codebase maintainable. The apex DAG acts as a traffic controller, ensuring dependencies are strictly honored without creating a single, monolithic, 500-task DAG.

DAG ATTRIBUTES:
- Schedule: 0 2 * * * (2:00 AM Daily)
- SLA: 6 hours (Overall Platform SLA)
- Support Runbook: https://wiki.omniretail.com/data/runbooks/master-dag
==============================================================================
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
