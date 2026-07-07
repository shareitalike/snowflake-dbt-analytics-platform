terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.73"
    }
  }
}

variable "database_name" { type = string }
variable "schema_name" { type = string }

# Row Access Policy (Tenant Isolation / Region Isolation)
# Ensures that regional managers can only see rows belonging to their assigned region.
resource "snowflake_row_access_policy" "region_isolation" {
  name     = "REGION_ISOLATION_POLICY"
  database = var.database_name
  schema   = var.schema_name
  
  signature {
    name = "REGION_ID"
    type = "VARCHAR"
  }

  row_access_expression = <<-EOT
    case
      when current_role() = 'GLOBAL_ADMIN_ROLE' then true
      when current_role() = 'US_MANAGER_ROLE' and REGION_ID = 'US' then true
      when current_role() = 'EU_MANAGER_ROLE' and REGION_ID = 'EU' then true
      else false
    end
  EOT
  comment = "Isolates row visibility based on the user's regional role assignment."
}
