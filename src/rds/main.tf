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
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.terraform_db_credentials.secret_string)
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = data.aws_subnets.public_subnets.ids
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
  vpc_security_group_ids = [data.aws_security_group.ec2.id]
  db_name                = "terraform_db"
  username               = "postgres"
  password               = local.db_creds.password
}


