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

variable "kubeconfig" {
  description = "Rendered kubeconfig JSON for the cluster."
  type        = string
  sensitive   = true
}

variable "cluster_oidc" {
  description = "OIDC issuer for IRSA."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
