data "aws_vpc" "vpc" {
  tags = {
    Name = "terraform vpc"
  }
}

data "aws_subnets" "public_subnets" {
  tags = {
    Name = "terraform public subnet*"
  }
}

data "aws_security_group" "ec2" {
  tags = {
    Name = "terraform security group"
  }
}

data "aws_secretsmanager_secret" "terraform_db" {
  name = "terraform_postgres_db"
}

data "aws_secretsmanager_secret_version" "terraform_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.terraform_db.id
}
