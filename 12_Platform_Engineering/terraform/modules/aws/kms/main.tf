resource "aws_kms_key" "enterprise_secrets_key" {
  description             = "KMS Key for encrypting Airflow and Snowflake secrets in AWS Secrets Manager"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  is_enabled              = true
  
  tags = {
    Environment = var.environment
    Domain      = "Security"
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/${var.environment}-enterprise-secrets-key"
  target_key_id = aws_kms_key.enterprise_secrets_key.key_id
}
