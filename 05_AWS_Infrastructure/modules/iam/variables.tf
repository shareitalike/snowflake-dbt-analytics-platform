variable "environment" {}
variable "project" {}
variable "snowflake_storage_integration_iam_user_arn" {
  description = "The IAM user ARN provided by Snowflake for the storage integration"
  type        = string
}
variable "snowflake_storage_integration_external_id" {
  description = "The External ID provided by Snowflake for the storage integration"
  type        = string
}
variable "landing_bucket_arn" {
  type = string
}
variable "raw_bucket_arn" {
  type = string
}
