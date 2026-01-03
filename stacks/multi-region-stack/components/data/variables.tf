variable "environment" {
  description = "Environment name."
  type        = string
}

variable "region" {
  description = "AWS region for the deployment."
  type        = string
}

variable "table_name" {
  description = "Base table name for DynamoDB."
  type        = string
}

variable "stream_enabled" {
  description = "Whether to enable DynamoDB streams."
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Whether to enable point-in-time recovery."
  type        = bool
  default     = true
}

variable "replica_regions" {
  description = "List of replica regions for the global table."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
