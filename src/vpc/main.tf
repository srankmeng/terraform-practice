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

# resource "aws_eip" "nat_eip" {
#   vpc        = true
#   depends_on = [aws_internet_gateway.igw]
# }
# resource "aws_nat_gateway" "nat" {
#   subnet_id     = element(aws_subnet.public_subnets_frontend.*.id, 0)
#   allocation_id = aws_eip.nat_eip.id
#   depends_on    = [aws_internet_gateway.igw]
#   tags = {
#     Name = "terraform nat"
#   }
# }

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

resource "aws_subnet" "public_subnets_backend_lb" {
  count      = length(var.public_subnet_backend_lb_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public_subnet_backend_lb_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  # map_public_ip_on_launch = true # when use nat gateway
  
  tags = {
    Name = "terraform public subnet application loadbalancer ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets_backend" {
  count      = length(var.private_subnet_backend_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private_subnet_backend_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform private subnet application ${count.index + 1}"
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
    Name = "terraform web route table"
  }
}

resource "aws_route_table" "route_table_backend_lb" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "terraform application loadbalancer route table"
  }
}

resource "aws_route_table" "route_table_backend" {
  vpc_id = aws_vpc.vpc.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.nat.id
  # }
  
  tags = {
    Name = "terraform application route table"
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

resource "aws_route_table_association" "public_subnet_asso_backend_lb" {
  count = length(var.public_subnet_backend_lb_cidrs)
  subnet_id = element(aws_subnet.public_subnets_backend_lb[*].id, count.index)
  route_table_id = aws_route_table.route_table_backend_lb.id
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
