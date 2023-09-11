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
  # map_public_ip_on_launch = true # when use nat gateway
  
  tags = {
    Name = "terraform public subnet web ${count.index + 1}"
  }
}


resource "aws_route_table" "route_table_frontend" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "terraform web route table"
  }
}


resource "aws_route_table_association" "public_subnet_asso_frontend" {
  count = length(var.public_subnet_frontend_cidrs)
  subnet_id = element(aws_subnet.public_subnets_frontend[*].id, count.index)
  route_table_id = aws_route_table.route_table_frontend.id
}
