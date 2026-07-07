"""
ENTERPRISE DAG: Customer Ingestion Pipeline

DAG Purpose: Monitors AWS S3 for arriving Fivetran/Kafka JSON files and triggers Snowflake Snowpipe.
Trigger Type: Scheduled (@hourly) / Event-driven via S3 Sensor.
Upstream Dependencies: Fivetran extraction, AWS S3 file arrival.
Downstream Dependencies: enterprise_orchestration_dag (Master DAG).
SLA: 45 minutes.
Retry Policy: 3 retries, 5 minute delay.
Failure Notification Flow: Slack #alerts-data-eng and PagerDuty (Sev 2).
Estimated Runtime: 2-5 minutes.
Business Owner: VP of Customer Experience.
Support Runbook: https://wiki.omniretail.com/data/runbooks/customer-ingestion
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'data_eng_team',
    'depends_on_past': False,
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'snowflake_conn_id': 'snowflake_default',
    'sla': timedelta(minutes=45),
}

with DAG(
    'customer_ingestion_dag',
    default_args=default_args,
    description='Senses S3 files and triggers Snowpipe for Customer domain.',
    schedule_interval='@hourly',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['domain:customer', 'tier:1', 'phase:bronze'],
) as dag:

    start = EmptyOperator(task_id='start')

    sense_s3_file = S3KeySensor(
        task_id='sense_customer_data_in_s3',
        bucket_key='inbound/customers/{{ ds }}/*.json',
        bucket_name='{{ var.value.s3_bronze_bucket }}',
        aws_conn_id='aws_default',
        timeout=3600,
        poke_interval=60,
    )

    trigger_snowpipe = SnowflakeOperator(
        task_id='trigger_snowpipe_refresh',
        sql="ALTER PIPE omniretail.raw.pipe_customers REFRESH;",
    )

    end = EmptyOperator(task_id='end')

    start >> sense_s3_file >> trigger_snowpipe >> end
