data "aws_ecr_repository" "backend_ecr" {
  name = "tf-nest"
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

data "aws_subnets" "private_subnets_backend" {
  tags = {
    Name = "terraform private subnet backend*"
  }
}
