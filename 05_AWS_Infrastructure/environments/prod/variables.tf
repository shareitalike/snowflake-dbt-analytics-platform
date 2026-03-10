variable "environment" {
  default = "prod"
}
variable "project" {
  default = "omniretail"
}
variable "aws_region" {
  default = "us-east-1"
}
variable "kms_key_arn" {}
variable "snowflake_storage_integration_iam_user_arn" {}
variable "snowflake_storage_integration_external_id" {}
