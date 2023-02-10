# variable "aws_access_key" {}

# variable "aws_secret_key"{}

variable "profile" {
 type        = string
 default     = "default"
}

variable "region" {
 type        = string
 default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "azs" {
 type        = list(string)
 default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}