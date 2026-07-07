variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "snowflake_account" {
  type        = string
  description = "Snowflake Account Identifier"
}

variable "snowflake_user" {
  type        = string
  description = "Snowflake Service Account User (e.g. TERRAFORM_SVC)"
}
