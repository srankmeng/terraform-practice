# https://developer.hashicorp.com/terraform/language/expressions/version-constraints#version-constraint-syntax
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
  region  = "ap-southeast-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.terraform_db_current.secret_string)
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#argument-reference
resource "aws_db_instance" "rds_instance" {
  identifier             = "rds-terraform"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "12.13"
  skip_final_snapshot    = true
  publicly_accessible    = true
  # vpc_security_group_ids = [aws_security_group.uddin.id]
  # security_groups
  db_name                = local.db_creds.dbname
  username               = local.db_creds.username
  password               = local.db_creds.password
}