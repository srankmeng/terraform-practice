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

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "terraform vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "terraform igw"
  }
}

resource "aws_subnet" "public_subnets_frontend" {
  count      = length(var.public_subnet_frontend_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public_subnet_frontend_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform public subnet frontend ${count.index + 1}"
  }
}

resource "aws_subnet" "public_subnets_api_gw" {
  count      = length(var.public_subnet_api_gw_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public_subnet_api_gw_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform public subnet api gw ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets_backend" {
  count      = length(var.private_subnet_backend_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private_subnet_backend_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform private subnet backend ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets_database" {
  count      = length(var.private_subnet_database_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private_subnet_database_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform private subnet database ${count.index + 1}"
  }
}

resource "aws_route_table" "route_table_frontend" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "terraform frontend route table"
  }
}

resource "aws_route_table" "route_table_api_gw" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "terraform api gw route table"
  }
}

resource "aws_route_table" "route_table_backend" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "terraform backend route table"
  }
}

resource "aws_route_table" "route_table_database" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "terraform database route table"
  }
}

resource "aws_route_table_association" "public_subnet_asso_frontend" {
  count = length(var.public_subnet_frontend_cidrs)
  subnet_id = element(aws_subnet.public_subnets_frontend[*].id, count.index)
  route_table_id = aws_route_table.route_table_frontend.id
}

resource "aws_route_table_association" "public_subnet_asso_api_gw" {
  count = length(var.public_subnet_api_gw_cidrs)
  subnet_id = element(aws_subnet.public_subnets_api_gw[*].id, count.index)
  route_table_id = aws_route_table.route_table_api_gw.id
}

resource "aws_route_table_association" "private_subnet_asso_backend" {
  count = length(var.private_subnet_backend_cidrs)
  subnet_id = element(aws_subnet.private_subnets_backend[*].id, count.index)
  route_table_id = aws_route_table.route_table_backend.id
}

resource "aws_route_table_association" "private_subnet_asso_database" {
  count = length(var.private_subnet_database_cidrs)
  subnet_id = element(aws_subnet.private_subnets_database[*].id, count.index)
  route_table_id = aws_route_table.route_table_database.id
}

resource "aws_security_group" "rds" {
  name = "terraform-sg-rds"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Postgres"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform security group rds"
  }
}