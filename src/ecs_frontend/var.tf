variable "profile" {
  type        = string
  default     = "default"
}

variable "region" {
  type        = string
  default     = "ap-southeast-1"
}

variable "docker_variables"{
  default = [
    {
      "name": "API_URL",
      "value": "http://backend-alb-1066745585.ap-southeast-1.elb.amazonaws.com/users"
    }
  ]
}
