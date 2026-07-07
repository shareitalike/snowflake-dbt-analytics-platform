terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.73" # Enforcing exact minor version to prevent state drift
    }
  }
}
