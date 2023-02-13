data "aws_ecr_repository" "frontend_ecr" {
  name = "tf-nuxt"
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

data "aws_vpc" "vpc" {
  tags = {
    Name = "terraform vpc"
  }
}

data "aws_subnets" "public_subnets_frontend" {
  tags = {
    Name = "terraform public subnet frontend*"
  }
}
