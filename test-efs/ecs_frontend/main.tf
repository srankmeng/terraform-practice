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

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend_task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "frontend_task",
      "image": "${data.aws_ecr_repository.frontend_ecr.repository_url}",
      "essential": true,
      "mountPoints": [
        {
          "containerPath": "/etc/newman/reports",
          "sourceVolume": "test-report"
        }
      ],
      "environment": ${jsonencode([
        {
          "name": "COLLECTION_FILES",
          "value": "aqua_farm.postman_collection.json"
        },
        {
          "name": "ENV_FILE",
          "value": "aqua_farm.postman_environment.json"
        },
        {
          "name": "HOST",
          "value": "localhost:7001"
        }
      ])},
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/tf-frontend",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      },
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  task_role_arn            = data.aws_iam_role.ecsTaskExecutionRole.arn
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn

  volume {
    name = "test-report"

    efs_volume_configuration {
      file_system_id = data.aws_efs_file_system.report.id
      root_directory = "/"
      transit_encryption = "DISABLED"
    }
  }
}

resource "aws_security_group" "service_security_group" {
  name = "terraform-sv-sg-web"
  vpc_id = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/ecs/tf-frontend"
  tags = {
    Name = "terraform logs - users"
  }
}