# ------------------------------------------------------------------------------
# IAM Roles for Enterprise Data Platform
# ------------------------------------------------------------------------------

# 1. Snowflake Storage Integration Role
data "aws_iam_policy_document" "snowflake_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.snowflake_storage_integration_iam_user_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.snowflake_storage_integration_external_id]
    }
  }
}

resource "aws_iam_role" "snowflake_storage_role" {
  name               = "${var.project}-${var.environment}-snowflake-s3-role"
  assume_role_policy = data.aws_iam_policy_document.snowflake_trust_policy.json
}

data "aws_iam_policy_document" "snowflake_s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket"
    ]
    resources = [
      var.landing_bucket_arn,
      "${var.landing_bucket_arn}/*",
      var.raw_bucket_arn,
      "${var.raw_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "snowflake_s3_policy" {
  name   = "${var.project}-${var.environment}-snowflake-s3-policy"
  policy = data.aws_iam_policy_document.snowflake_s3_access.json
}

resource "aws_iam_role_policy_attachment" "snowflake_attach" {
  role       = aws_iam_role.snowflake_storage_role.name
  policy_arn = aws_iam_policy.snowflake_s3_policy.arn
}

# 2. Airflow Service Account Role
resource "aws_iam_role" "airflow_service_role" {
  name = "${var.project}-${var.environment}-airflow-svc-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "airflow.amazonaws.com"
      }
    }]
  })
}

# 3. CI/CD GitHub Actions Role (OIDC)
resource "aws_iam_role" "cicd_role" {
  name = "${var.project}-${var.environment}-github-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity",
      Effect = "Allow",
      Principal = {
        Federated = "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      }
    }]
  })
}
