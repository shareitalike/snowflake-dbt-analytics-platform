"""
==============================================================================
FILE: inventory_pipeline_dag.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: A domain-specific DAG for the Inventory pipeline that triggers a Snowpark Stored Procedure to handle complex JSON array flattening.
DESIGN DECISIONS: Abstracted from the master orchestration DAG. Triggered specifically by the master DAG (schedule is None).
WHY: Separating complex Python transformation logic (Snowpark) into its own DAG makes debugging easier. If the inventory flattening fails, it doesn't clutter the master DAG's visual graph.

DAG ATTRIBUTES:
- SLA: 2 hours
- Retry Policy: 2 retries, 5 minute delay
- Support Runbook: https://wiki.omniretail.com/data/runbooks/inventory-snowpark
==============================================================================
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'data_eng_supply_chain',
    'depends_on_past': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'snowflake_conn_id': 'snowflake_default',
    'sla': timedelta(hours=2),
}

with DAG(
    'inventory_pipeline_dag',
    default_args=default_args,
    description='Triggers Snowpark Stored Procedure to parse JSON.',
    schedule_interval=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['domain:inventory', 'tier:2', 'phase:snowpark'],
) as dag:

    start = EmptyOperator(task_id='start')

    trigger_snowpark_flattener = SnowflakeOperator(
        task_id='trigger_snowpark_flattener',
        sql="CALL omniretail.processing.sp_flatten_inventory_json();",
        deferrable=True, 
    )

    end = EmptyOperator(task_id='end')

    start >> trigger_snowpark_flattener >> end
