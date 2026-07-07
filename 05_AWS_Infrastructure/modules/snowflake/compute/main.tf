terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.85"
    }
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, prod)"
}

resource "snowflake_warehouse" "ingest" {
  name                = "WH_INGEST_${upper(var.environment)}"
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Dedicated warehouse for Snowpipe and Airflow polling."
}

resource "snowflake_warehouse" "transform" {
  name                = "WH_TRANSFORM_${upper(var.environment)}"
  warehouse_size      = "MEDIUM"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Dedicated warehouse for Snowpark Python logic."
}

resource "snowflake_warehouse" "dbt" {
  name                = "WH_DBT_${upper(var.environment)}"
  warehouse_size      = "LARGE"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Dedicated warehouse for dbt Cloud SQL transformations."
}

resource "snowflake_warehouse" "bi" {
  name                = "WH_BI_${upper(var.environment)}"
  warehouse_size      = "SMALL"
  max_cluster_count   = 5
  min_cluster_count   = 1
  scaling_policy      = "STANDARD"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Multi-cluster warehouse for concurrent Power BI queries."
}

resource "snowflake_warehouse" "adhoc" {
  name                = "WH_ADHOC_${upper(var.environment)}"
  warehouse_size      = "XSMALL"
  auto_suspend        = 300
  auto_resume         = true
  initially_suspended = true
  comment             = "Ad-hoc queries for Data Analysts."
}

resource "snowflake_warehouse" "admin" {
  name                = "WH_ADMIN_${upper(var.environment)}"
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Administrative tasks and DDL execution."
}
