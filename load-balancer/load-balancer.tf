resource "aws_lb" "load-balancer" {
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.default.ids
  security_groups            = [aws_security_group.public.id]
  enable_deletion_protection = false
}

resource "aws_security_group" "public" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "listener" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.load-balancer.arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = 200
      message_body = "Hello, world"
    }
  }
}

resource "aws_lb_listener_rule" "service-a" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = module.service-a.target_group.arn
  }
  condition {
    path_pattern {
      values = ["/service-a*"]
    }
  }
}

resource "aws_lb_listener_rule" "service-b" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 101
  action {
    type             = "forward"
    target_group_arn = module.service-b.target_group.arn
  }
  condition {
    path_pattern {
      values = ["/service-b*"]
    }
  }
}
