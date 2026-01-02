terraform {
  required_version = ">= 1.9.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59"
    }
  }
}

locals {
  name_prefix         = "${var.environment}-app"
  target_group_suffix = regexreplace(var.target_group_arn, "^arn:[^:]+:elasticloadbalancing:[^:]+:[0-9]+:", "")
}

# Discover the ALB from its DNS name to power dashboards and alarms without
# forcing the caller to share internal identifiers.
data "aws_lb" "from_dns" {
  dns_name = var.alb_dns_name
}

resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${local.name_prefix}-ops"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "text"
        x    = 0
        y    = 0
        width  = 24
        height = 3
        properties = {
          markdown = "## ${local.name_prefix} overview\nApplication endpoint: ${var.alb_dns_name}"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 3
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", data.aws_lb.from_dns.arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          title  = "ALB Requests"
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 3
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.ecs_service_name, "ClusterName", var.ecs_cluster_name]
          ]
          period = 60
          stat   = "Average"
          title  = "ECS CPU Utilization"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-dashboard"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${local.name_prefix}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0.5
  dimensions = {
    LoadBalancer = data.aws_lb.from_dns.arn_suffix
    TargetGroup  = local.target_group_suffix
  }

  alarm_description = "Alarm when ALB target latency exceeds 500ms"
  treat_missing_data = "missing"

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-latency"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_unhealthy" {
  alarm_name          = "${local.name_prefix}-ecs-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  dimensions = {
    TargetGroup = local.target_group_suffix
    LoadBalancer = data.aws_lb.from_dns.arn_suffix
  }

  alarm_description = "Alarm when no healthy ECS tasks are registered"
  treat_missing_data = "breaching"

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-ecs-health"
    Environment = var.environment
  })
}
