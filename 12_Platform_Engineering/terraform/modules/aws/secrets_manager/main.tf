resource "aws_secretsmanager_secret" "enterprise_secret" {
  name        = "${var.environment}/${var.secret_name}"
  description = var.description
  kms_key_id  = var.kms_key_id

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# The actual secret value should NEVER be passed via Terraform plain text.
# The value is ignored in the lifecycle block to allow external scripts (or Airflow UI)
# to rotate the secret without Terraform overwriting it on the next apply.

resource "aws_secretsmanager_secret_version" "secret_val" {
  secret_id     = aws_secretsmanager_secret.enterprise_secret.id
  secret_string = var.initial_secret_string

  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
}
