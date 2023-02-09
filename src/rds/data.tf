data "aws_vpc" "vpc" {
  tags = {
    Name = "VPC was created by Terraform"
  }
}

data "aws_subnets" "public_subnets" {
  tags = {
    Name = "Public Subnet * was created by Terraform"
  }
}

data "aws_security_group" "ec2" {
  name = "terraform-sg"
}

data "aws_secretsmanager_secret" "terraform_db" {
  name = "terraform_postgres_db"
}

data "aws_secretsmanager_secret_version" "terraform_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.terraform_db.id
}
