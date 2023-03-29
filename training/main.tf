# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.16"
#     }
#   }

#   required_version = ">= 1.2.0"
# }

# provider "aws" {
#   region  = var.region
#   profile = var.profile
#   # access_key = "AKIAXXXXXXXXX"
#   # secret_key = "XXXXXXXXXXXXX"
# }

locals {
  bucket_name = "tf-meng"
}

# resource "aws_s3_bucket" "site" {
#   bucket = local.bucket_name
#   force_destroy = true
# }

output "name" {
  value = local.bucket_name
  # value = var.username
  # value = var.profile
}




# variable "myfile_content" {
#   type        = string
#   description = "Content of myfile.txt for test"
#   default     = "Hello from Terraform. eiei2"
# }

# resource "local_file" "myfile" {
#   filename = "myfile.txt"
#   content  = var.myfile_content
# }

# output "myfile_id" {
#   value = local_file.myfile.id
# }


# terraform {
#   required_providers {
#     docker = {
#       source = "kreuzwerker/docker"
#       version = "~> 3.0.1"
#     }
#   }
# }

# provider "docker" {}

# resource "docker_image" "nginx" {
#   name         = "nginx:latest"
#   keep_locally = false
# }

# resource "docker_container" "nginx" {
#   image = docker_image.nginx.image_id
#   name  = "training docker terraform"
#   ports {
#     internal = 80
#     external = 8000
#   }
# }