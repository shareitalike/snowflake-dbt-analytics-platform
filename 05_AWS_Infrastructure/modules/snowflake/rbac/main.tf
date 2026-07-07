terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.85"
    }
  }
}

# 1. Functional Roles
resource "snowflake_account_role" "etl_admin" {
  name    = "ETL_ADMIN"
  comment = "Manages ingestion and external stages"
}

resource "snowflake_account_role" "data_engineer" {
  name    = "DATA_ENGINEER"
  comment = "Manages Silver layer and Snowpark logic"
}

resource "snowflake_account_role" "analytics_engineer" {
  name    = "ANALYTICS_ENGINEER"
  comment = "Manages Gold dimensional modeling via dbt"
}

resource "snowflake_account_role" "bi_developer" {
  name    = "BI_DEVELOPER"
  comment = "Manages Power BI Semantic Layers"
}

resource "snowflake_account_role" "business_analyst" {
  name    = "BUSINESS_ANALYST"
  comment = "Exploratory data analysis on Gold views"
}

resource "snowflake_account_role" "read_only" {
  name    = "READ_ONLY"
  comment = "Strictly read-only access for executives"
}

# Service Roles
resource "snowflake_account_role" "airflow_service" {
  name    = "AIRFLOW_SERVICE"
  comment = "Automated orchestration service role"
}

resource "snowflake_account_role" "dbt_service" {
  name    = "DBT_SERVICE"
  comment = "Automated CI/CD transformation role"
}

# 2. Role Hierarchy
# SYSADMIN owns everything
resource "snowflake_grant_account_role" "etl_to_sysadmin" {
  role_name        = snowflake_account_role.etl_admin.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "de_to_sysadmin" {
  role_name        = snowflake_account_role.data_engineer.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "ae_to_sysadmin" {
  role_name        = snowflake_account_role.analytics_engineer.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "bi_to_sysadmin" {
  role_name        = snowflake_account_role.bi_developer.name
  parent_role_name = "SYSADMIN"
}

# Service Accounts inherit from Engineering
resource "snowflake_grant_account_role" "airflow_to_etl" {
  role_name        = snowflake_account_role.airflow_service.name
  parent_role_name = snowflake_account_role.etl_admin.name
}

resource "snowflake_grant_account_role" "dbt_to_ae" {
  role_name        = snowflake_account_role.dbt_service.name
  parent_role_name = snowflake_account_role.analytics_engineer.name
}

# Consumption Roles Chain
resource "snowflake_grant_account_role" "ba_to_bi" {
  role_name        = snowflake_account_role.business_analyst.name
  parent_role_name = snowflake_account_role.bi_developer.name
}
