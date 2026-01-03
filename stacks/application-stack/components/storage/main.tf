terraform {
  required_version = ">= 1.9.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  name_prefix = "${var.environment}-app"
}

resource "aws_kms_key" "db" {
  description             = "KMS key for encrypting database resources"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-db-kms"
    Environment = var.environment
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-db-subnets"
    Environment = var.environment
  })
}

resource "random_password" "db" {
  length           = 20
  special          = true
  override_characters = "!#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${local.name_prefix}-db-password"
  kms_key_id = aws_kms_key.db.arn

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-db-password"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

resource "aws_db_instance" "postgres" {
  identifier             = "${local.name_prefix}-postgres"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t4g.micro"
  username               = "app_user"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]
  skip_final_snapshot    = true
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.db.arn
  multi_az               = false
  publicly_accessible    = false
  deletion_protection    = false
  backup_retention_period = 7

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-postgres"
    Environment = var.environment
    Layer       = "storage"
  })
}

output "db_endpoint" {
  description = "PostgreSQL endpoint address."
  value       = aws_db_instance.postgres.address
}

output "db_username" {
  description = "Database username."
  value       = aws_db_instance.postgres.username
}

output "db_password_secret_arn" {
  description = "ARN of the secret storing the DB password."
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_security_group_id" {
  description = "Security group protecting the database tier."
  value       = var.db_security_group_id
}
