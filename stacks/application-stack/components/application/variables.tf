variable "environment" {
  description = "Environment name used for tagging and naming."
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service powering the application."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for dashboard queries."
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB fronting the service."
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener used by the service."
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN attached to the ALB listener."
  type        = string
}

variable "region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Base map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
