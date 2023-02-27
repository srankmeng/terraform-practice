data "aws_vpc" "vpc" {
  tags = {
    Name = "terraform vpc"
  }
}

data "aws_subnets" "private_subnets_backend" {
  tags = {
    Name = "terraform private subnet application*"
  }
}

data "aws_route_table" "route_table_backend" {
  tags = {
    Name = "terraform application route table"
  }
}