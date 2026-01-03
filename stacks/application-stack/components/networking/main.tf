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
  name_prefix = "${var.environment}-app"
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-vpc"
    Environment = var.environment
    Layer       = "networking"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-igw"
    Environment = var.environment
  })
}

resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-public-${count.index}"
    Environment = var.environment
    Tier        = "public"
  })
}

resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-private-${count.index}"
    Environment = var.environment
    Tier        = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-public-rt"
    Environment = var.environment
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public ingress to Application Load Balancer"
  vpc_id      = aws_vpc.this.id

  ingress {
    description      = "Allow HTTP inbound"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-alb-sg"
    Environment = var.environment
  })
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Application traffic from ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-app-sg"
    Environment = var.environment
  })
}

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Database traffic from application tier"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Allow Postgres from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-db-sg"
    Environment = var.environment
  })
}

data "aws_availability_zones" "available" {}

output "vpc_id" {
  description = "The ID of the VPC created for the application."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Security group used by the ALB."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group used by compute resources."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security group used by the database tier."
  value       = aws_security_group.db.id
}
