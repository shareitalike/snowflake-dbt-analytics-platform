variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
}

variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "omniretail"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  type        = string
}
