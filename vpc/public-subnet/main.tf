variable "availability_zone" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cidr_block" {
  type = string
}

resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_id
  availability_zone       = var.availability_zone
  cidr_block              = var.cidr_block
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_route_tables" "main" {
  vpc_id = var.vpc_id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_route" "igw_rt" {
  # route_table_id = data.aws_vpc.main.main_route_table_id
  route_table_id         = data.aws_route_tables.main.ids[0]
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

output "subnet" {
  value = aws_subnet.public
}
