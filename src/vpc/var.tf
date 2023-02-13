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

variable "public_subnet_frontend_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_api_gw_cidrs" {
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_subnet_backend_cidrs" {
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "private_subnet_database_cidrs" {
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24"]
}
variable "azs" {
 type        = list(string)
 default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}