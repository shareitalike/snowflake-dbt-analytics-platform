"""
==============================================================================
FILE: sales_pipeline_dag.py
PHASE: 11 - Airflow Orchestration

EXPLANATION: An Airflow DAG running on a near real-time schedule (every 15 minutes) to process high-velocity Sales CDC streams.
DESIGN DECISIONS: Explicitly triggers Snowflake native Tasks (EXECUTE TASK) rather than putting the complex SQL directly into Airflow. Updates a custom cdc_watermarks table upon success.
WHY: For near real-time pipelines, putting heavy compute logic in Airflow creates latency. Pushing the heavy lifting down to Snowflake native Tasks while using Airflow strictly for triggering and watermark management is the most performant architecture.

DAG ATTRIBUTES:
- Schedule: */15 * * * *
- SLA: 10 minutes
- Support Runbook: https://wiki.omniretail.com/data/runbooks/sales-cdc
==============================================================================
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'data_eng_sales',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
    'snowflake_conn_id': 'snowflake_default',
    'sla': timedelta(minutes=10),
}

with DAG(
    'sales_pipeline_dag',
    default_args=default_args,
    description='Executes Snowflake Tasks to process Sales CDC Streams.',
    schedule_interval='*/15 * * * *',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['domain:sales', 'tier:1', 'phase:cdc'],
) as dag:

    start = EmptyOperator(task_id='start')

    execute_sales_cdc_task = SnowflakeOperator(
        task_id='execute_sales_cdc_task',
        sql="EXECUTE TASK omniretail.raw.task_process_sales_stream;",
    )
    
    update_watermark = SnowflakeOperator(
        task_id='update_cdc_watermark',
        sql="""
            UPDATE omniretail.raw.cdc_watermarks 
            SET last_processed_at = CURRENT_TIMESTAMP()
            WHERE table_name = 'sales_stream';
        """
    )

    end = EmptyOperator(task_id='end')

    start >> execute_sales_cdc_task >> update_watermark >> end
