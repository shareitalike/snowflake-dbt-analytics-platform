provider "snowflake" {
  account  = var.snowflake_account
  username = var.snowflake_user
  role     = "ACCOUNTADMIN" # Enterprise IaC requires elevated privileges to manage roles and users
  
  # Password injected via ENV VAR: SNOWFLAKE_PASSWORD for CI/CD Security
}
