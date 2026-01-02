variable "environment" {
  description = "Environment name used for tagging and naming."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC hosting the compute stack."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where ALB will reside."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs used by ECS tasks."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB."
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID for ECS tasks."
  type        = string
}

variable "db_security_group_id" {
  description = "Security group ID for database access (used for dependency tracking)."
  type        = string
}

variable "db_endpoint" {
  description = "Database endpoint used by the application container."
  type        = string
}

variable "db_username" {
  description = "Database user name."
  type        = string
}

variable "db_password_secret_arn" {
  description = "Secret ARN containing the database password."
  type        = string
}

variable "container_image" {
  description = "Container image to deploy."
  type        = string
}

variable "desired_count" {
  description = "Desired ECS task count."
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU units for the Fargate task."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MiB) for the Fargate task."
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "HTTP health check path."
  type        = string
  default     = "/"
}

variable "region" {
  description = "AWS region for log streaming configuration."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Base map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
