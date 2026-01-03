terraform {
  required_version = ">= 1.9.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = jsondecode(var.kubeconfig).clusters[0].cluster.server
  token                  = jsondecode(var.kubeconfig).users[0].user.token
  cluster_ca_certificate = base64decode(jsondecode(var.kubeconfig).clusters[0].cluster["certificate-authority-data"])
}

provider "helm" {
  kubernetes {
    host                   = jsondecode(var.kubeconfig).clusters[0].cluster.server
    token                  = jsondecode(var.kubeconfig).users[0].user.token
    cluster_ca_certificate = base64decode(jsondecode(var.kubeconfig).clusters[0].cluster["certificate-authority-data"])
  }
}

locals {
  name_prefix = "${var.environment}-eks"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${local.name_prefix}-alb-controller"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/alb-controller.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "${local.name_prefix}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.cluster_oidc, "https://", "" )}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster_oidc, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [jsonencode({
    clusterName = var.cluster_name,
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
      }
    }
  })]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}

resource "kubernetes_namespace" "sample" {
  metadata {
    name = "sample-app"
  }
}

resource "helm_release" "sample_app" {
  name       = "sample-app"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  namespace  = kubernetes_namespace.sample.metadata[0].name

  values = [jsonencode({
    service = { type = "ClusterIP" },
    replicaCount = 2,
    resources = {
      limits = { cpu = "200m", memory = "256Mi" },
      requests = { cpu = "100m", memory = "128Mi" }
    }
  })]
}
