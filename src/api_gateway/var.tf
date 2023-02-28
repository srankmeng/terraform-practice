variable "profile" {
  type        = string
  default     = "default"
}

variable "region" {
  type        = string
  default     = "ap-southeast-1"
}

variable "allow_headers" {
  type        = string
  default     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
}

variable "allow_methods" {
  type        = string
  default     = "'GET,POST,PUT,OPTIONS'"
}

variable "allow_origin" {
  type        = string
  default     = "'https://d3gtphjcnn0s2m.cloudfront.net'"
}
