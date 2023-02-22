data "aws_ecr_repository" "backend_ecr" {
  name = "tf-nest"
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
  name = "tf-ecsTaskExecutionRole"
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

data "aws_subnet" "private_subnet_backend" {
  for_each = toset(data.aws_subnets.private_subnets_backend.ids)
  id       = each.value
}

data "aws_secretsmanager_secret" "terraform_db" {
  name = "terraform_postgres_db"
}

data "aws_secretsmanager_secret_version" "terraform_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.terraform_db.id
}

data "aws_service_discovery_dns_namespace" "ecs_dns" {
  name = "private.local"
  type = "DNS_PRIVATE"
}

data "aws_service_discovery_service" "ecs_users_service" {
  name         = "users"
  namespace_id = data.aws_service_discovery_dns_namespace.ecs_dns.id
}