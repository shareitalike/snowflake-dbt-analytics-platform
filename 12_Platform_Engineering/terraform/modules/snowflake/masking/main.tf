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

# Dynamic Data Masking Policy for PII
# If the user is the PII_ADMIN_ROLE, they see the raw data.
# Otherwise, the data is heavily obfuscated.
resource "snowflake_masking_policy" "pii_email_masking" {
  name               = "MASK_EMAIL_POLICY"
  database           = var.database_name
  schema             = var.schema_name
  value_data_type    = "VARCHAR"
  masking_expression = <<-EOT
    case
      when current_role() in ('PII_ADMIN_ROLE') then val
      else regexp_replace(val, '.+\\@', '*****@') -- e.g. jsmith@gmail.com -> *****@gmail.com
    end
  EOT
  return_data_type   = "VARCHAR"
  comment            = "Masks email addresses for non-authorized roles"
}
