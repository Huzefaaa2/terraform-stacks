variable "environment" {
  description = "Environment name used for tagging and naming."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where storage resources are provisioned."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the database subnet group."
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID that allows application traffic to the database."
  type        = string
}

variable "tags" {
  description = "Base map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
