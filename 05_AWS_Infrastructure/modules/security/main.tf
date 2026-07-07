# ------------------------------------------------------------------------------
# Security Baselines (CloudTrail, GuardDuty, AWS Config)
# ------------------------------------------------------------------------------

# 1. CloudTrail for API Auditing
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${var.project}-${var.environment}-cloudtrail-logs"
  force_destroy = true
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}

# 2. GuardDuty for Threat Detection
resource "aws_guardduty_detector" "main" {
  enable = true
}

# 3. AWS Config for Compliance
resource "aws_iam_role" "aws_config_role" {
  name = "${var.project}-${var.environment}-aws-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_attach" {
  role       = aws_iam_role.aws_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.aws_config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}
