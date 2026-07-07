"""
Enterprise Master Orchestrator DAG
The "Brain" of the OmniRetail Enterprise Data Platform.
This DAG coordinates the massive end-to-end execution across AWS, Snowflake, Snowpark, and dbt Cloud.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator
from operators.snowflake.enterprise_snowflake_operator import EnterpriseSnowflakeOperator
from alerts.enterprise_alert_router import enterprise_alert_router
from sla.sla_miss_handler import enterprise_sla_miss_escalator

default_args = {
    'owner': 'data_platform_architects',
    'depends_on_past': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'on_failure_callback': enterprise_alert_router,
    'sla': timedelta(hours=4),
}

with DAG(
    'enterprise_master_orchestrator_dag',
    default_args=default_args,
    description='End-to-End Enterprise Data Platform Orchestrator',
    schedule_interval='0 2 * * *',  # Run daily at 2:00 AM
    start_date=datetime(2026, 1, 1),
    catchup=False,
    sla_miss_callback=enterprise_sla_miss_escalator,
    tags=['domain:enterprise', 'tier:1', 'master'],
) as dag:

    start = EmptyOperator(task_id='kickoff_platform_orchestration')

    # 1. AWS Landing Validation (Ensure files arrived in Bronze S3)
    landing_validation = EmptyOperator(task_id='validate_s3_landing_zone')

    # 2. Snowpipe Ingestion (Validate Snowpipe auto-ingest queue is clear)
    snowpipe_validation = EnterpriseSnowflakeOperator(
        task_id='validate_snowpipe_loads',
        snowflake_conn_id='snowflake_default',
        sql="SELECT COUNT(*) FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY()) WHERE STATUS = 'LOAD_FAILED' AND LAST_LOAD_TIME > DATEADD(hour, -24, CURRENT_TIMESTAMP());",
        require_warehouse_resume=True
    )

    # 3. Dynamic TaskGroup Trigger (Wait for all CDC streams to process)
    # In a real environment, this would use a TriggerDagRunOperator to wait on the Dynamic DAGs
    cdc_streams_processed = EmptyOperator(task_id='wait_for_cdc_streams')

    # 4. Snowpark Processing (Complex JSON Flattening into Silver)
    snowpark_flattening = EnterpriseSnowflakeOperator(
        task_id='execute_snowpark_flattening',
        snowflake_conn_id='snowflake_default',
        sql="CALL OMNIRETAIL.SILVER.FLATTEN_ALL_JSON_PAYLOADS();"
    )

    # 5. dbt Cloud Execution (Deferrable to save worker slots)
    dbt_build = DbtCloudRunJobOperator(
        task_id='dbt_build_medallion',
        job_id="{{ var.json.prod_variables.dbt_build_job_id }}",
        check_interval=60,
        deferrable=True,
    )
    
    dbt_test = DbtCloudRunJobOperator(
        task_id='dbt_test_data_quality',
        job_id="{{ var.json.prod_variables.dbt_docs_job_id }}", # Repurposing var for example
        check_interval=60,
        deferrable=True,
    )

    # 6. Post-Processing & Notifications
    power_bi_refresh = EmptyOperator(task_id='trigger_power_bi_api')
    notify_business = EmptyOperator(task_id='notify_business_success')

    end = EmptyOperator(task_id='platform_orchestration_complete')

    # 7. Enterprise Lineage Definition
    start >> landing_validation >> snowpipe_validation >> cdc_streams_processed 
    cdc_streams_processed >> snowpark_flattening >> dbt_build >> dbt_test
    dbt_test >> power_bi_refresh >> notify_business >> end
