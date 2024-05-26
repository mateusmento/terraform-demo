variable "service_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ami" {
  type = string
}

variable "instance_count" {
  type = number
}

locals {
  final_instance_count = var.instance_count * length(var.subnet_ids)
}

resource "aws_instance" "service" {
  count         = local.final_instance_count
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
  key_name      = "ec2-key"
  user_data = templatefile("./install.sh", {
    service_name = var.service_name
  })

  tags = {
    Name = "${var.service_name}-${count.index}"
  }
}

resource "aws_lb_target_group" "group" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    interval            = 30 # specifies a interval in seconds to wait before each health check
    timeout             = 5  # specifies a time in seconds to wait before the health check fails
    unhealthy_threshold = 10 # specifies after how many failed health checks a target is considered unhealthy
    healthy_threshold   = 3  # specifies after how many successful health checks a unhealthy target is considered healthy
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = local.final_instance_count
  target_group_arn = aws_lb_target_group.group.arn
  target_id        = aws_instance.service[count.index].id
}

output "target_group" {
  value = aws_lb_target_group.group
}

output "services" {
  value = aws_instance.service
}
