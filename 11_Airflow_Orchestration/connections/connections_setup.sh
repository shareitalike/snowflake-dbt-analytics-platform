#!/bin/bash
# Enterprise Airflow Local Connections Setup
# WARNING: Do NOT hardcode passwords here in production.
# In Prod, these are managed via AWS Secrets Manager backend.

# Snowflake Connection (Keypair authentication preferred)
airflow connections add 'snowflake_default' \
    --conn-type 'snowflake' \
    --conn-login 'AIRFLOW_SVC_USER' \
    --conn-password 'dummy_password_for_local' \
    --conn-extra '{"account": "omniretail", "warehouse": "XLARGE_ETL_WH", "database": "PROD_DB", "region": "us-east-1"}'

# AWS Connection (Assume Role)
airflow connections add 'aws_default' \
    --conn-type 'aws' \
    --conn-extra '{"role_arn": "arn:aws:iam::123456789012:role/airflow_s3_role", "region_name": "us-east-1"}'

# dbt Cloud API
airflow connections add 'dbt_cloud_default' \
    --conn-type 'dbt_cloud' \
    --conn-password 'dbtc_xxxxxx' \
    --conn-extra '{"account_id": 12345}'

# Slack Webhook (For Alerts)
airflow connections add 'slack_api_default' \
    --conn-type 'slack' \
    --conn-password 'xoxb-xxxx'
