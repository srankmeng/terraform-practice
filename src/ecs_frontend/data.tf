data "aws_ecr_repository" "frontend_ecr" {
  name = "tf-nuxt"
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

data "aws_subnets" "public_subnets_frontend" {
  tags = {
    Name = "terraform public subnet web*"
  }
}

data "aws_api_gateway_rest_api" "api_gw" {
  name = "api_gw"
}
