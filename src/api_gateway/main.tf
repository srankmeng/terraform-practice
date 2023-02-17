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

resource "aws_api_gateway_rest_api" "api_gw"{
  name = "api_gw"
  description = "terraform api gw"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
  # request_parameters = {
  #   "method.request.path.proxy" = true
  # }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.aws_lb.backend_alb.dns_name}/users"
 
  # request_parameters =  {
  #   "integration.request.path.proxy" = "method.request.path.proxy"
  # }
}

resource "aws_api_gateway_resource" "resource2" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "method2" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.resource2.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration2" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_resource.resource2.id
  http_method = aws_api_gateway_method.method2.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.aws_lb.backend2_alb.dns_name}/products"
}
resource "aws_api_gateway_deployment" "ApiDeploymentDev" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  description = "Deployed at ${timestamp()}"
  stage_name  = "dev"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource,
      aws_api_gateway_method.method,
      aws_api_gateway_integration.integration,
      aws_api_gateway_resource.resource2,
      aws_api_gateway_method.method2,
      aws_api_gateway_integration.integration2,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
