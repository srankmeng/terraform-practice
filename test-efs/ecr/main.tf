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

resource "aws_ecr_repository" "frontend_ecr" {
  name = "tf-nuxt"
  force_delete = true

  tags = {
    Name = "terraform frontend ecr"
  }
}