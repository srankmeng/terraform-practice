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

resource "aws_service_discovery_private_dns_namespace" "ecs_dns" {
  name        = "private.local"
  description = "terraform private dns service"
  vpc         = data.aws_vpc.vpc.id
  tags = {
    Name = "terraform dns namespace"
  }
}

resource "aws_service_discovery_service" "ecs_service" {
  name = "users"
  description = "terraform ecs service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_dns.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "ecs_service2" {
  name = "products"
  description = "terraform ecs service2"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_dns.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}