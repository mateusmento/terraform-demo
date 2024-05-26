terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.17"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

data "aws_availability_zones" "az" {
  state         = "available"
  exclude_names = ["sa-east-1b", "sa-east-1c"]
}

locals {
  availability_zones = data.aws_availability_zones.az.names
}

output "availability_zones" {
  value = local.availability_zones
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

module "public_subnets" {
  source            = "./public-subnet"
  count             = length(local.availability_zones)
  availability_zone = local.availability_zones[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index * 2}.0/24"
}

module "private_subnets" {
  source            = "./private-subnet"
  count             = length(local.availability_zones)
  availability_zone = local.availability_zones[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index * 2 + 1}.0/24"
  public_subnet_id  = module.public_subnets[count.index].subnet.id
}

resource "aws_instance" "public" {
  count                  = length(module.public_subnets)
  ami                    = "ami-05dc908211c15c11d"
  instance_type          = "t2.micro"
  subnet_id              = module.public_subnets[count.index].subnet.id
  vpc_security_group_ids = [aws_security_group.public.id]
  user_data              = templatefile("./install.sh", { service_name : "service-${count.index}" })
  key_name               = "ec2-key"
}

resource "aws_instance" "private" {
  count                  = length(module.private_subnets)
  ami                    = "ami-05dc908211c15c11d"
  instance_type          = "t2.micro"
  subnet_id              = module.private_subnets[count.index].subnet.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = "ec2-key"
}

resource "aws_security_group" "public" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol        = "TCP"
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.public.id]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
