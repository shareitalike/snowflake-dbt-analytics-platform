variable "environment" {
  description = "Environment Prefix"
  type        = string
}

# 1. Create Base Roles
resource "snowflake_role" "data_eng" {
  name    = "${var.environment}_DATA_ENGINEER_ROLE"
  comment = "Grants read/write access to Bronze/Silver, ownership of ETL compute."
}

resource "snowflake_role" "data_analyst" {
  name    = "${var.environment}_DATA_ANALYST_ROLE"
  comment = "Grants read-only access to Gold DB for Power BI / Tableau."
}

resource "snowflake_role" "sysadmin" {
  name = "SYSADMIN"
}

# 2. Build Role Hierarchy (RBAC)
# SYSADMIN inherits the permissions of the Data Engineer Role
resource "snowflake_role_grants" "eng_to_sysadmin" {
  role_name = snowflake_role.data_eng.name
  roles     = [snowflake_role.sysadmin.name]
}

resource "snowflake_role_grants" "analyst_to_sysadmin" {
  role_name = snowflake_role.data_analyst.name
  roles     = [snowflake_role.sysadmin.name]
}
