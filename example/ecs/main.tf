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

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "terraform vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "terraform igw"
  }
}

resource "aws_subnet" "public_subnets" {
  count      = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform public subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform private subnet ${count.index + 1}"
  }
}

resource "aws_route_table" "alb_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "terraform alb route table"
  }
}

resource "aws_route_table" "api_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  
  tags = {
    Name = "terraform api route table"
  }
}

resource "aws_route_table_association" "public_subnet_asso" {
  count = length(var.public_subnet_cidrs)
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.alb_route_table.id
}

resource "aws_route_table_association" "private_subnet_asso" {
  count = length(var.private_subnet_cidrs)
  subnet_id = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.api_route_table.id
}

resource "aws_ecr_repository" "api_ecr" {
  name = "tf-api"
  force_delete = true

  tags = {
    Name = "terraform api ecr"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "tf_cluster"

  tags = {
    Name = "terraform cluster"
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "tf-ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "sm_policy" {
  name = "terraform_sm_access_permissions"
  role = aws_iam_role.ecsTaskExecutionRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_ecs_task_definition" "api_task" {
  family                   = "api_task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "api_task",
      "image": "${aws_ecr_repository.api_ecr.repository_url}",
      "secrets": ${jsonencode([
        {
          "name": "DB_PASSWORD",
          "valueFrom": "${aws_secretsmanager_secret_version.db_secret_version.arn}",
        }
      ])},
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
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
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_service" "api_service" {
  name            = "api_service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # number of task

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = aws_ecs_task_definition.api_task.family
    container_port   = 3000
  }

  network_configuration {
    subnets = [for subnet in aws_subnet.private_subnets : subnet.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.api_security_group.id]
  }
}

resource "aws_security_group" "api_security_group" {
  name = "terraform-api-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_nat_gateway" "nat" {
  subnet_id     = element(aws_subnet.public_subnets.*.id, 0)
  allocation_id = aws_eip.nat_eip.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "terraform nat"
  }
}

resource "aws_lb" "alb" {
  name               = "terraform-alb"
  load_balancer_type = "application"
  subnets = [for subnet in aws_subnet.public_subnets : subnet.id]
  security_groups = [aws_security_group.alb_security_group.id]

  tags = {
    Name = "terraform alb"
  }
}

resource "aws_security_group" "alb_security_group" {
  name = "terraform-alb-sg"
  vpc_id = aws_vpc.vpc.id

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

resource "aws_lb_target_group" "alb_target_group" {
  name        = "terraform-alb-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

########################
### secret manager
########################
resource "random_password" "random_db_password" {
  length = 16
  special = false
}

locals {
  db_password = random_password.random_db_password.result
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "terraform_postgres_db"
  description = "terraform secret"
  recovery_window_in_days = 0

  tags = {
    Name = "terraform secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = local.db_password
}


########################
### rds
########################
resource "aws_subnet" "database_subnets" {
  count      = length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.database_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  
  tags = {
    Name = "terraform database subnet ${count.index + 1}"
  }
}

resource "aws_route_table" "route_table_database" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "terraform database route table"
  }
}

resource "aws_route_table_association" "database_subnet_asso" {
  count = length(var.database_subnet_cidrs)
  subnet_id = element(aws_subnet.database_subnets[*].id, count.index)
  route_table_id = aws_route_table.route_table_database.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.database_subnets : subnet.id]
}

resource "aws_security_group" "rds" {
  name = "terraform-sg-rds"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Postgres"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform security group rds"
  }
}

resource "aws_db_instance" "rds" {
  identifier             = "rds-terraform"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "12.13"
  skip_final_snapshot    = true
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_name                = "terraform_db"
  username               = "postgres"
  password               = local.db_password
}