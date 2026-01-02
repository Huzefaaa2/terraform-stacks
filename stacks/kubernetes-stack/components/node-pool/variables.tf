variable "environment" {
  description = "Environment name."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_oidc" {
  description = "OIDC issuer for IRSA."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the node group."
  type        = list(string)
}

variable "desired_size" {
  description = "Desired node count."
  type        = number
}

variable "min_size" {
  description = "Minimum node count."
  type        = number
}

variable "max_size" {
  description = "Maximum node count."
  type        = number
}

variable "instance_types" {
  description = "Instance types for the node group."
  type        = list(string)
}

variable "cluster_version" {
  description = "EKS version for AMI selection."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
