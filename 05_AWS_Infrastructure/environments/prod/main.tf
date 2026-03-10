provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
    }
  }
}

module "s3" {
  source      = "../../modules/s3"
  environment = var.environment
  project     = var.project
  kms_key_arn = var.kms_key_arn
}

module "iam" {
  source                                     = "../../modules/iam"
  environment                                = var.environment
  project                                    = var.project
  snowflake_storage_integration_iam_user_arn = var.snowflake_storage_integration_iam_user_arn
  snowflake_storage_integration_external_id  = var.snowflake_storage_integration_external_id
  landing_bucket_arn                         = module.s3.landing_bucket_arn
  raw_bucket_arn                             = module.s3.raw_bucket_arn
}

module "sqs_sns" {
  source             = "../../modules/sqs_sns"
  environment        = var.environment
  project            = var.project
  landing_bucket_arn = module.s3.landing_bucket_arn
  landing_bucket_id  = module.s3.landing_bucket_id
}

module "security" {
  source      = "../../modules/security"
  environment = var.environment
  project     = var.project
}

module "snowflake_rbac" {
  source = "../../modules/snowflake/rbac"
}

module "snowflake_compute" {
  source      = "../../modules/snowflake/compute"
  environment = var.environment
}

module "snowflake_storage" {
  source      = "../../modules/snowflake/storage"
  environment = var.environment
}
