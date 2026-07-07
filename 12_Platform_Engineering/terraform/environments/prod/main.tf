terraform {
  backend "s3" {
    bucket         = "omniretail-terraform-state-prod"
    key            = "platform-engineering/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-prod"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.73"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "snowflake" {
  account  = var.snowflake_account
  username = var.snowflake_user
  # Password injected via ENV VAR: SNOWFLAKE_PASSWORD
  role     = "SYSADMIN"
}

# ==========================================
# AWS Infrastructure
# ==========================================
module "bronze_s3_bucket" {
  source      = "../../modules/aws/s3"
  bucket_name = "omniretail-bronze-prod-landing"
  tags        = { Environment = "Prod", Domain = "Enterprise" }
}

# ==========================================
# Snowflake Infrastructure
# ==========================================
module "data_eng_warehouse" {
  source           = "../../modules/snowflake/warehouses"
  warehouse_name   = "PROD_DATA_ENG_WH"
  warehouse_size   = "LARGE"
  auto_suspend     = 60
  statement_timeout = 7200 # 2 Hours Max
}

module "bi_warehouse" {
  source           = "../../modules/snowflake/warehouses"
  warehouse_name   = "PROD_BI_WH"
  warehouse_size   = "MEDIUM"
  auto_suspend     = 300   # 5 Minutes (keep warm for analysts)
  statement_timeout = 600  # 10 Minutes Max
}

module "snowflake_databases" {
  source      = "../../snowflake/databases"
  environment = "PROD"
}

module "snowflake_roles" {
  source      = "../../snowflake/roles"
  environment = "PROD"
}

module "snowflake_monitors" {
  source      = "../../snowflake/resource_monitors"
}
