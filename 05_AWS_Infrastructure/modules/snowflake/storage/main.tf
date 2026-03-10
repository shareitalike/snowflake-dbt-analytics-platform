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

# 1. RAW Database (Bronze Layer)
resource "snowflake_database" "raw" {
  name                        = "DB_${upper(var.environment)}_RAW"
  data_retention_time_in_days = 1
  comment                     = "Immutable landing zone for raw source data (Bronze)"
}

# 2. CURATED Database (Silver Layer)
resource "snowflake_database" "curated" {
  name                        = "DB_${upper(var.environment)}_CURATED"
  data_retention_time_in_days = 1
  comment                     = "Standardized, conformed entities (Silver)"
}

# 3. ANALYTICS Database (Gold Layer)
resource "snowflake_database" "analytics" {
  name                        = "DB_${upper(var.environment)}_ANALYTICS"
  data_retention_time_in_days = 90
  comment                     = "Dimensional Data Marts and Semantic Layer (Gold)"
}

# 4. GOVERNANCE Database
resource "snowflake_database" "governance" {
  name                        = "DB_${upper(var.environment)}_GOVERNANCE"
  data_retention_time_in_days = 30
  comment                     = "Centralized governance policies and security mappings"
}

# 5. METADATA Database
resource "snowflake_database" "metadata" {
  name                        = "DB_${upper(var.environment)}_METADATA"
  data_retention_time_in_days = 30
  comment                     = "Platform operational metadata and dbt artifacts"
}

# 6. REFERENCE Database
resource "snowflake_database" "reference" {
  name                        = "DB_${upper(var.environment)}_REFERENCE"
  data_retention_time_in_days = 1
  comment                     = "Static enterprise reference data"
}

# 7. SANDBOX Database
resource "snowflake_database" "sandbox" {
  name                        = "DB_${upper(var.environment)}_SANDBOX"
  data_retention_time_in_days = 0
  comment                     = "Ephemeral data science and analyst sandbox"
}
