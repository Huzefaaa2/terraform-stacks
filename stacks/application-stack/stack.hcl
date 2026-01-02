stack {
  name        = "application-stack"
  description = "Reference Terraform Stack that deploys a full web application footprint (networking, storage, compute, and app runtime) as a single unit."
  version     = "1.0.0"

  tags = {
    product     = "terraform-stacks"
    environment = "multi"
  }
}

provider "aws" {
  source  = "hashicorp/aws"
  version = "~> 5.59"
}

variable "environment" {
  type        = string
  description = "Friendly name for the environment (prod, staging, dev)."
  default     = "prod"
}

variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"
}

variable "deployments" {
  description = "Optional map of deployment names to region overrides for multi-instance rollouts."
  type = map(object({
    region = string
  }))
  default = {
    prod = { region = "us-east-1" }
  }
}

component "networking" {
  source = "./components/networking"

  inputs = {
    environment          = var.environment
    cidr_block           = "10.10.0.0/16"
    az_count             = 3
    public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
    private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
    tags                 = stack.tags
  }
}

component "storage" {
  source = "./components/storage"

  inputs = {
    environment        = var.environment
    vpc_id             = component.networking.outputs.vpc_id
    private_subnet_ids = component.networking.outputs.private_subnet_ids
    tags               = stack.tags
  }

  depends_on = ["networking"]
}

component "compute" {
  source = "./components/compute"

  inputs = {
    environment             = var.environment
    vpc_id                  = component.networking.outputs.vpc_id
    public_subnet_ids       = component.networking.outputs.public_subnet_ids
    private_subnet_ids      = component.networking.outputs.private_subnet_ids
    alb_security_group_id   = component.networking.outputs.alb_security_group_id
    app_security_group_id   = component.networking.outputs.app_security_group_id
    db_security_group_id    = component.storage.outputs.db_security_group_id
    db_endpoint             = component.storage.outputs.db_endpoint
    db_username             = component.storage.outputs.db_username
    db_password_secret_arn  = component.storage.outputs.db_password_secret_arn
    container_image         = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
    desired_count           = 2
    cpu                     = 512
    memory                  = 1024
    health_check_path       = "/"
    region                  = var.region
    tags                    = stack.tags
  }

  depends_on = ["networking", "storage"]
}

component "application" {
  source = "./components/application"

  inputs = {
    environment       = var.environment
    ecs_service_name  = component.compute.outputs.ecs_service_name
    alb_dns_name      = component.compute.outputs.alb_dns_name
    alb_listener_arn  = component.compute.outputs.alb_listener_arn
    ecs_cluster_name  = component.compute.outputs.ecs_cluster_name
    target_group_arn  = component.compute.outputs.target_group_arn
    region            = var.region
    tags              = stack.tags
  }

  depends_on = ["compute"]
}

deployment "default" {
  inputs = {
    environment = var.environment
    region      = var.region
  }

  provider "aws" {
    config = {
      region = var.region
    }
  }
}

dependency "regions" {
  for_each = var.deployments

  deployment "regional" {
    inputs = {
      environment = "${var.environment}-${each.key}"
      region      = each.value.region
    }

    provider "aws" {
      config = {
        region = each.value.region
      }
    }
  }
}
