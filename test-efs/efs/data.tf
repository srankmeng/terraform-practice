data "aws_vpc" "vpc" {
  tags = {
    Name = "terraform vpc"
  }
}