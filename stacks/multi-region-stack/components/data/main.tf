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
  table_name = "${var.environment}-${var.table_name}"
}

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB at ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name        = "${local.table_name}-kms"
    Environment = var.environment
  })
}

resource "aws_dynamodb_table" "this" {
  name           = local.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "pk"
  range_key      = "sk"
  stream_enabled = var.stream_enabled
  stream_view_type = var.stream_enabled ? "NEW_AND_OLD_IMAGES" : null
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  point_in_time_recovery {
    enabled = var.backup_enabled
  }

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  tags = merge(var.tags, {
    Name        = local.table_name
    Environment = var.environment
    Layer       = "data"
  })
}

output "table_name" {
  value       = aws_dynamodb_table.this.name
  description = "Name of the DynamoDB table"
}

output "table_arn" {
  value       = aws_dynamodb_table.this.arn
  description = "ARN of the DynamoDB table"
}
