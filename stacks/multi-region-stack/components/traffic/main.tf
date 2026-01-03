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
  name_prefix = "${var.environment}-mr"
}

data "aws_route53_zone" "this" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_route53_health_check" "alb" {
  fqdn              = var.alb_dns_name
  type              = "HTTP"
  resource_path     = "/health"
  request_interval  = 30
  failure_threshold = 3
  port              = 80

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-alb-hc"
    Environment = var.environment
  })
}

resource "aws_route53_record" "failover" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.environment}.${var.zone_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = local.name_prefix
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.alb.id
}

output "record_fqdn" {
  value       = aws_route53_record.failover.fqdn
  description = "DNS record created for this deployment"
}
