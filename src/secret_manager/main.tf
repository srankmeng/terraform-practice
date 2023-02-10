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

resource "random_password" "random_db_password" {
  length = 16
  special = false
}

locals {
  # # when use json (key/value)
  # db_password = tomap({
  #   password = random_password.random_db_password.result
  # })

  # when use plain text
  db_password = random_password.random_db_password.result
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "terraform_postgres_db"
  description = "terraform secret"
  recovery_window_in_days = 0

  tags = {
    Name = "terraform secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  # secret_string = jsonencode(local.db_password) # when use json (key/value)
  secret_string = local.db_password # when use plain text
}