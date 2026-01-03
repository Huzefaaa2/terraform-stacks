variable "environment" {
  description = "Environment name."
  type        = string
}

variable "region" {
  description = "AWS region for DNS health checks."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name to target."
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for alias records."
  type        = string
}

variable "zone_name" {
  description = "Route53 hosted zone name (must exist)."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
