data "aws_lb" "backend_alb" {
  tags = {
    Name = "terraform backend alb"
  }
}

data "aws_lb" "backend2_alb" {
  tags = {
    Name = "terraform backend2 alb"
  }
}