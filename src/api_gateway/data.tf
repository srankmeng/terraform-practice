data "aws_lb" "backend_users_alb" {
  tags = {
    Name = "terraform backend users alb"
  }
}

data "aws_lb" "backend_products_alb" {
  tags = {
    Name = "terraform backend products alb"
  }
}