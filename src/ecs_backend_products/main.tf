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

resource "aws_ecs_task_definition" "backend_products_task" {
  family                   = "backend_products_task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "backend_products_task",
      "image": "${data.aws_ecr_repository.backend_products_ecr.repository_url}",
      "secrets": ${jsonencode([
        {
          "name": "DB_PASSWORD",
          "valueFrom": "${data.aws_secretsmanager_secret_version.terraform_db_credentials.arn}",
        }
      ])},
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/tf-backend",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs",
           "awslogs-create-group": "true"
        }
      },
      "environment": ${jsonencode([
        {
          "name": "USER_API_URL",
          "value": "http://${data.aws_service_discovery_service.ecs_users_service.name}.${data.aws_service_discovery_dns_namespace.ecs_dns.name}:5000",
        }
      ])},
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5001,
          "hostPort": 5001
        }
      ],
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

resource "aws_ecs_service" "backend_products_service" {
  name            = "backend_products_service"
  cluster         = data.aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend_products_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_products_target_group.arn
    container_name   = aws_ecs_task_definition.backend_products_task.family
    container_port   = 5001
  }

  network_configuration {
    subnets = data.aws_subnets.private_subnets_backend.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.service_products_security_group.id]
  }

  service_registries {
    registry_arn = data.aws_service_discovery_service.ecs_products_service.arn
  }
}

resource "aws_security_group" "service_products_security_group" {
  name = "terraform-sv-products-sg-api"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [aws_security_group.lb_products_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "backend_products_alb" {
  name               = "backend-products-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.public_subnets_backend_lb.ids
  security_groups = [aws_security_group.lb_products_security_group.id]

  tags = {
    Name = "terraform backend products alb"
  }
}

resource "aws_security_group" "lb_products_security_group" {
  name = "terraform-lb2-sg-api"
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

resource "aws_lb_target_group" "backend_products_target_group" {
  name        = "backend-products-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_lb_listener" "backend_products_listener" {
  load_balancer_arn = aws_lb.backend_products_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_products_target_group.arn
  }
}

resource "aws_cloudwatch_log_group" "log" {
  name = "/ecs/tf-backend"
}
