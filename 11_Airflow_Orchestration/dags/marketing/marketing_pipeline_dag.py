"""
ENTERPRISE DAG: Marketing Pipeline

DAG Purpose: Pulls campaign data via external REST APIs (e.g., Salesforce, Marketo) and lands it in Snowflake.
Trigger Type: Scheduled (@daily).
Upstream Dependencies: Marketo API.
Downstream Dependencies: enterprise_orchestration_dag.
SLA: 4 hours.
Retry Policy: 5 retries, 1 minute delay (jitter) due to API rate limits.
Failure Notification Flow: Slack #alerts-marketing-data.
Estimated Runtime: 15 minutes.
Business Owner: VP of Marketing.
Support Runbook: https://wiki.omniretail.com/data/runbooks/marketing-api
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.http.operators.http import SimpleHttpOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.operators.empty import EmptyOperator
import json

default_args = {
    'owner': 'data_eng_marketing',
    'depends_on_past': False,
    'retries': 5, # High retries for API rate limits
    'retry_delay': timedelta(minutes=1),
}

with DAG(
    'marketing_pipeline_dag',
    default_args=default_args,
    description='Extracts campaign data from REST APIs into Snowflake RAW.',
    schedule_interval='@daily',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['domain:marketing', 'tier:2', 'phase:bronze'],
) as dag:

    start = EmptyOperator(task_id='start')

    # Example API Call (Using HttpOperator rather than a massive Python Operator)
    trigger_marketo_extract = SimpleHttpOperator(
        task_id='trigger_marketo_extract',
        http_conn_id='marketo_api_default',
        endpoint='rest/v1/campaigns.json',
        method='GET',
        log_response=True,
    )
    
    # In a real environment, the API payload would be parsed and uploaded to S3, 
    # then copied into Snowflake. For brevity, simulating the Snowflake load.
    load_to_snowflake = SnowflakeOperator(
        task_id='load_campaigns_to_raw',
        snowflake_conn_id='snowflake_default',
        sql="COPY INTO omniretail.raw.marketing_campaigns FROM @omniretail.raw.s3_stage/campaigns/;",
    )

    end = EmptyOperator(task_id='end')

    start >> trigger_marketo_extract >> load_to_snowflake >> end
