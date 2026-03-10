# terraform.tfvars
environment = "prod"
project     = "omniretail"
aws_region  = "us-east-1"

# NOTE: These values are provided by Snowflake after running:
# DESCRIBE INTEGRATION <integration_name>;
snowflake_storage_integration_iam_user_arn = "arn:aws:iam::123456789012:user/snowflake-svc"
snowflake_storage_integration_external_id  = "SNOWFLAKE_EXTERNAL_ID_VALUE"

kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/your-kms-key-id"
