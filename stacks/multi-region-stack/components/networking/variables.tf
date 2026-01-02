variable "environment" {
  description = "Environment name (e.g., prod, staging)."
  type        = string
}

variable "region" {
  description = "AWS region for the deployment."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "tags" {
  description = "Common tags to apply."
  type        = map(string)
  default     = {}
}
