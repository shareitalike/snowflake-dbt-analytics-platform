terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.73"
    }
  }
}

resource "snowflake_warehouse" "etl_warehouse" {
  name           = var.warehouse_name
  warehouse_size = var.warehouse_size
  auto_suspend   = var.auto_suspend
  auto_resume    = true
  initially_suspended = true
  
  # Enterprise FinOps Standard:
  statement_timeout_in_seconds = var.statement_timeout
  max_concurrency_level        = var.max_concurrency
}
