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

resource "aws_api_gateway_resource" "resource_users" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_method" "method_users" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.resource_users.id
  http_method   = "GET"
  authorization = "NONE"
  # request_parameters = {
  #   "method.request.path.proxy" = true
  # }
}

resource "aws_api_gateway_integration" "integration_users" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = aws_api_gateway_method.method_users.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.aws_lb.backend_users_alb.dns_name}/users"
 
  # request_parameters =  {
  #   "integration.request.path.proxy" = "method.request.path.proxy"
  # }
}

resource "aws_api_gateway_resource" "resource_products" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "method_products" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.resource_products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration_products" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_resource.resource_products.id
  http_method = aws_api_gateway_method.method_products.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.aws_lb.backend_products_alb.dns_name}/products"
}

resource "aws_api_gateway_resource" "resource_product_users" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_resource.resource_products.id
  path_part   = "product-users"
}

resource "aws_api_gateway_method" "method_product_users" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.resource_product_users.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration_product_users" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_resource.resource_product_users.id
  http_method = aws_api_gateway_method.method_product_users.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.aws_lb.backend_products_alb.dns_name}/products/product-users"
}
resource "aws_api_gateway_deployment" "ApiDeploymentDev" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  description = "Deployed at ${timestamp()}"
  stage_name  = "dev"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource_users,
      aws_api_gateway_method.method_users,
      aws_api_gateway_integration.integration_users,
      aws_api_gateway_resource.resource_products,
      aws_api_gateway_method.method_products,
      aws_api_gateway_integration.integration_products,
      aws_api_gateway_resource.resource_product_users,
      aws_api_gateway_method.method_product_users,
      aws_api_gateway_integration.integration_product_users,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
