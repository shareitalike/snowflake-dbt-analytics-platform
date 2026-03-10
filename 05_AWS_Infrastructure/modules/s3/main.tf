# ------------------------------------------------------------------------------
# S3 Buckets for Data Platform
# ------------------------------------------------------------------------------

locals {
  buckets = {
    landing    = "${var.project}-${var.environment}-landing-zone"
    raw        = "${var.project}-${var.environment}-raw-data"
    archive    = "${var.project}-${var.environment}-archive"
    quarantine = "${var.project}-${var.environment}-quarantine"
    analytics  = "${var.project}-${var.environment}-analytics-exports"
    logs       = "${var.project}-${var.environment}-platform-logs"
    backup     = "${var.project}-${var.environment}-backups"
  }
}

resource "aws_s3_bucket" "datalake" {
  for_each = local.buckets
  bucket   = each.value

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Layer       = each.key
  }
}

# ------------------------------------------------------------------------------
# Default Encryption (KMS)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = aws_s3_bucket.datalake

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# ------------------------------------------------------------------------------
# Versioning
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = aws_s3_bucket.datalake

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# Public Access Block (Security Best Practice)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  for_each = aws_s3_bucket.datalake

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# Lifecycle Rules (Archive & Backup specific)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "archive_lifecycle" {
  bucket = aws_s3_bucket.datalake["archive"].id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"
    
    filter {}

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_lifecycle" {
  bucket = aws_s3_bucket.datalake["raw"].id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    
    filter {}

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}
