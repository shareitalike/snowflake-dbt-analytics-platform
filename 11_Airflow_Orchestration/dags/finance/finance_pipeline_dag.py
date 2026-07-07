"""
ENTERPRISE DAG: Finance Reconciliation Pipeline

DAG Purpose: Executes complex End-of-Month (EOM) financial reconciliation logic in Snowflake via Stored Procedures.
Trigger Type: Scheduled (@monthly).
Upstream Dependencies: enterprise_orchestration_dag (Master).
Downstream Dependencies: None.
SLA: 24 hours.
Retry Policy: 1 retry, 15 minute delay.
Failure Notification Flow: Slack #alerts-finance-data.
Estimated Runtime: 1 hour.
Business Owner: Corporate Controller.
Support Runbook: https://wiki.omniretail.com/data/runbooks/finance-reconciliation
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
