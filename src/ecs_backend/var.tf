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
      "name": "DB_PASSWORD",
      "value": "lLCLmocVuX2CxsFp"
    }
  ]
}
