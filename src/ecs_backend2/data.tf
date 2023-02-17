data "aws_ecr_repository" "backend2_ecr" {
  name = "tf-nest-2"
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = "tf_cluster"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "terraform vpc"
  }
}

data "aws_subnets" "public_subnets_backend_lb" {
  tags = {
    Name = "terraform public subnet application loadbalancer*"
  }
}

data "aws_subnets" "private_subnets_backend" {
  tags = {
    Name = "terraform private subnet application*"
  }
}

data "aws_secretsmanager_secret" "terraform_db" {
  name = "terraform_postgres_db"
}

data "aws_secretsmanager_secret_version" "terraform_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.terraform_db.id
}
