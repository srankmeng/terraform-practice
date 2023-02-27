terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

resource "aws_security_group" "vpce_security_group" {
  name = "terraform-vpce-sg"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name = "terraform vpc endpoint sg"
  }
}

resource "aws_vpc_endpoint" "secret" {
  vpc_id = data.aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpce_security_group.id]
  subnet_ids = data.aws_subnets.private_subnets_backend.ids
  private_dns_enabled = true
  tags = {
    "Name" = "terraform secrect vpc endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id = data.aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpce_security_group.id]
  subnet_ids = data.aws_subnets.private_subnets_backend.ids
  private_dns_enabled = true
  tags = {
    "Name" = "terraform ecr.dkr vpc endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id = data.aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.vpce_security_group.id]
  subnet_ids = data.aws_subnets.private_subnets_backend.ids
  tags = {
    "Name" = "terraform ecr.api vpc endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id = data.aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [data.aws_route_table.route_table_backend.id]
  tags = {
    "Name" = "terraform s3(ecr) vpc endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [aws_security_group.vpce_security_group.id]
  subnet_ids = data.aws_subnets.private_subnets_backend.ids
  tags = {
    Name = "terraform logs vpc endpoint"
  }
}
