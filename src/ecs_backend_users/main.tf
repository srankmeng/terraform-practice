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

resource "aws_ecs_task_definition" "backend_users_task" {
  family                   = "backend_users_task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "backend_users_task",
      "image": "${data.aws_ecr_repository.backend_users_ecr.repository_url}",
      "secrets": ${jsonencode([
        {
          "name": "DB_PASSWORD",
          "valueFrom": "${data.aws_secretsmanager_secret_version.terraform_db_credentials.arn}",
        }
      ])},
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/tf-backend-users",
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
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_service" "backend_users_service" {
  name            = "backend_users_service"
  cluster         = data.aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend_users_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_users_target_group.arn
    container_name   = aws_ecs_task_definition.backend_users_task.family
    container_port   = 5000
  }

  network_configuration {
    subnets = data.aws_subnets.private_subnets_backend.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.service_users_security_group.id]
  }

  service_registries {
    registry_arn = data.aws_service_discovery_service.ecs_users_service.arn
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/ecs/tf-backend-users"
  tags = {
    Name = "terraform logs - users"
  }
}

resource "aws_security_group" "service_users_security_group" {
  name = "terraform-sv-users-sg-api"
  vpc_id = data.aws_vpc.vpc.id

  # allow speific load balancer
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [aws_security_group.lb_users_security_group.id]
  }

  # allow same private subnet
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [for subnet in data.aws_subnet.private_subnet_backend : subnet.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "backend_users_alb" {
  name               = "backend-users-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.public_subnets_backend_lb.ids
  security_groups = [aws_security_group.lb_users_security_group.id]

  tags = {
    Name = "terraform backend users alb"
  }
}

resource "aws_security_group" "lb_users_security_group" {
  name = "terraform-lb-users-sg-api"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic in from all sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "backend_users_target_group" {
  name        = "backend-users-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_lb_listener" "backend_users_listener" {
  load_balancer_arn = aws_lb.backend_users_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_users_target_group.arn
  }
}
