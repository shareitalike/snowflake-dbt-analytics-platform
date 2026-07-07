variable "warehouse_name" {
  type        = string
  description = "Name of the Snowflake Warehouse"
}

variable "warehouse_size" {
  type        = string
  description = "Size of the warehouse (e.g. XSMALL, LARGE)"
  default     = "XSMALL"
}

variable "auto_suspend" {
  type        = number
  description = "Seconds of inactivity before auto-suspend"
  default     = 60
}

variable "statement_timeout" {
  type        = number
  description = "Max execution time for a single query (FinOps safeguard)"
  default     = 3600
}

variable "max_concurrency" {
  type        = number
  description = "Max concurrent queries before queuing"
  default     = 8
}
