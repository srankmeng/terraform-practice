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

resource "aws_efs_file_system" "report" {
  creation_token = "tf-test-report"

  tags = {
    Name        = "tf-test-report"
  }
}

resource "aws_security_group" "access_efs_from_subnet" {
  name   = "tf-test-efs"
  vpc_id = data.aws_vpc.vpc.id

  # ingress {
  #   protocol    = "-1"
  #   self        = true
  #   from_port   = 0
  #   to_port     = 0
  #   cidr_blocks = [data.aws_subnet.testing.cidr_block]
  # }


   ingress {
      protocol    = "-1"
      self        = true
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"] # temp (not should all ip)
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_efs_mount_target" "testing" {
  file_system_id  = aws_efs_file_system.report.id
  subnet_id       = "subnet-0d7595a1366382629"
  security_groups = [aws_security_group.access_efs_from_subnet.id]
}

