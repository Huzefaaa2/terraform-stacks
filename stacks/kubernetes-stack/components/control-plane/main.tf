terraform {
  required_version = ">= 1.9.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  name_prefix = "${var.environment}-eks"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-vpc"
    Environment = var.environment
  })
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name                        = "${local.name_prefix}-private-${count.index}"
    Environment                 = var.environment
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_kms_key" "eks" {
  description             = "EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-kms"
    Environment = var.environment
  })
}

resource "aws_eks_cluster" "this" {
  name     = "${local.name_prefix}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

locals {
  kubeconfig = {
    apiVersion = "v1"
    clusters = [{
      cluster = {
        server                   = data.aws_eks_cluster.this.endpoint
        certificate-authority-data = data.aws_eks_cluster.this.certificate_authority[0].data
      }
      name = data.aws_eks_cluster.this.arn
    }]
    contexts = [{
      context = {
        cluster = data.aws_eks_cluster.this.arn
        user    = data.aws_eks_cluster.this.arn
      }
      name = data.aws_eks_cluster.this.arn
    }]
    current-context = data.aws_eks_cluster.this.arn
    kind            = "Config"
    preferences     = {}
    users = [{
      name = data.aws_eks_cluster.this.arn
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  }
}

output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs"
}

output "cluster_oidc" {
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
  description = "OIDC issuer for IRSA"
}

output "kubeconfig" {
  value       = jsonencode(local.kubeconfig)
  description = "Rendered kubeconfig for this cluster"
  sensitive   = true
}

output "cluster_version" {
  value       = var.cluster_version
  description = "EKS control plane version"
}
