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

locals {
  # # when use json (key/value)
  # db_creds = jsondecode(data.aws_secretsmanager_secret_version.terraform_db_credentials.secret_string)

  # when use plain text
  db_creds = data.aws_secretsmanager_secret_version.terraform_db_credentials.secret_string
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = data.aws_subnets.private_subnets_database.ids
}

resource "aws_security_group" "rds" {
  name = "terraform-sg-rds"
  vpc_id = data.aws_vpc.vpc.id

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

resource "aws_db_instance" "rds" {
  identifier             = "rds-terraform"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "12.13"
  skip_final_snapshot    = true
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_name                = "terraform_db"
  username               = "postgres"
  password               = local.db_creds
}


