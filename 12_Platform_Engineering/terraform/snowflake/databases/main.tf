variable "environment" {
  description = "Environment Prefix (e.g. PROD, DEV, QA)"
  type        = string
}

resource "snowflake_database" "bronze_db" {
  name    = "${var.environment}_BRONZE_DB"
  comment = "Raw JSON Landing Zone managed by Terraform"
}

resource "snowflake_database" "silver_db" {
  name    = "${var.environment}_SILVER_DB"
  comment = "Flattened and Cleansed Data managed by Terraform"
}

resource "snowflake_database" "gold_db" {
  name    = "${var.environment}_GOLD_DB"
  comment = "Business-Ready Star Schema managed by Terraform"
}

resource "snowflake_database" "metadata_db" {
  name    = "${var.environment}_METADATA_DB"
  comment = "Platform Observability and Control Tables"
}
