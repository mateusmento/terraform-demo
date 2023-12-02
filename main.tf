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
  profile = "default"
  region = "sa-east-1"
}

resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "demo-pub-subnet-sae1a" {
  vpc_id = aws_vpc.demo-vpc.id
  availability_zone = "sa-east-1a"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "demo-pub-subnet-sae1a"
  }
  depends_on = [ aws_vpc.demo-vpc ]
}

resource "aws_internet_gateway" "demo-netgw" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-netgw"
  }
}

resource "aws_route" "demo-vpc-main-route-table_demo-netgw" {
  route_table_id = aws_vpc.demo-vpc.main_route_table_id
  gateway_id = aws_internet_gateway.demo-netgw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [
    aws_internet_gateway.demo-netgw
  ]
}

resource "aws_security_group" "demo-pub-sg" {
  vpc_id = aws_vpc.demo-vpc.id
  name = "demo-pub-sg"
  tags = {
    Name = "demo-pub-sg"
  }
  depends_on = [ aws_vpc.demo-vpc ]
}

resource "aws_security_group_rule" "demo-pub-sg-ssh-allowed" {
  security_group_id = aws_security_group.demo-pub-sg.id
  type = "ingress"
  protocol = "TCP"
  from_port = 22
  to_port = 22
  cidr_blocks = ["0.0.0.0/0"]
  depends_on = [
    aws_security_group.demo-pub-sg
  ]
}

resource "aws_security_group_rule" "demo-pub-sg-http-allowed" {
  security_group_id = aws_security_group.demo-pub-sg.id
  type = "ingress"
  protocol = "TCP"
  from_port = 80
  to_port = 80
  cidr_blocks = ["0.0.0.0/0"]
  depends_on = [
    aws_security_group.demo-pub-sg
  ]
}

resource "aws_security_group_rule" "demo-pub-sg-out-bound-all-traffic-allowed" {
  security_group_id = aws_security_group.demo-pub-sg.id
  type = "egress"
  protocol = -1
  from_port = 0
  to_port = 0
  cidr_blocks = ["0.0.0.0/0"]
  depends_on = [
    aws_security_group.demo-pub-sg
  ]
}

resource "aws_instance" "demo-nginx" {
  ami = "ami-05dc908211c15c11d"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.demo-pub-subnet-sae1a.id
  security_groups = [ aws_security_group.demo-pub-sg.id ]
  key_name = "aws-ec2"
  tags = {
    Name = "demo-terraform-nginx"
  }
  depends_on = [
    aws_subnet.demo-pub-subnet-sae1a,
  ]
}
