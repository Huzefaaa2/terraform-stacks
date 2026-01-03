variable "environment" {
  description = "Environment name."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ECS service."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets for ALB."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the deployment."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group for ALB."
  type        = string
}

variable "app_security_group_id" {
  description = "Security group for ECS tasks."
  type        = string
}

variable "desired_count" {
  description = "Desired ECS task count."
  type        = number
  default     = 2
}

variable "cpu" {
  description = "Task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB."
  type        = number
  default     = 512
}

variable "listener_port" {
  description = "ALB listener port."
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Container image for the service."
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name to inject."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
