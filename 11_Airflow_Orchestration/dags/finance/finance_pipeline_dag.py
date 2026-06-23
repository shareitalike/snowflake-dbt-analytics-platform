"""
==============================================================================
FILE: finance_pipeline_dag.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: A specialized Airflow DAG designed to execute complex, End-of-Month (EOM) financial reconciliation logic via Snowflake Stored Procedures.
DESIGN DECISIONS: Configured with a @monthly schedule and a loose 24-hour SLA. Uses deferrable=True on the SnowflakeOperator to prevent blocking worker threads during long-running financial calculations.
WHY: Financial reconciliation is heavily compute-intensive and runs infrequently. Utilizing deferrable operators ensures that a multi-hour stored procedure doesn't consume an Airflow worker slot that could be used for high-frequency streaming DAGs.

DAG ATTRIBUTES:
- Schedule: @monthly
- SLA: 24 hours
- Support Runbook: https://wiki.omniretail.com/data/runbooks/finance-reconciliation
==============================================================================
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'data_eng_finance',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=15),
    'snowflake_conn_id': 'snowflake_default',
    'sla': timedelta(hours=24),
}

with DAG(
    'finance_pipeline_dag',
    default_args=default_args,
    description='Executes monthly financial reconciliation procedures.',
    schedule_interval='@monthly',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['domain:finance', 'tier:1', 'phase:silver'],
) as dag:

    start = EmptyOperator(task_id='start')

    execute_eom_reconciliation = SnowflakeOperator(
        task_id='execute_eom_reconciliation',
        sql="CALL omniretail.finance.sp_reconcile_eom_ledger();",
        deferrable=True, 
    )

    end = EmptyOperator(task_id='end')

    start >> execute_eom_reconciliation >> end
