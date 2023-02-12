data "aws_vpc" "vpc" {
  tags = {
    Name = "terraform vpc"
  }
}

data "aws_subnets" "private_subnets_database" {
  tags = {
    Name = "terraform private subnet database*"
  }
}

data "aws_security_group" "rds" {
  tags = {
    Name = "terraform security group rds"
  }
}

data "aws_secretsmanager_secret" "terraform_db" {
  name = "terraform_postgres_db"
}

data "aws_secretsmanager_secret_version" "terraform_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.terraform_db.id
}
