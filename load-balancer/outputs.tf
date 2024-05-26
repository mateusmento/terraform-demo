output "subnets" {
  value = data.aws_subnets.default.ids
}

output "service-a" {
  value = { for service_a in module.service-a.services : service_a.tags.Name => service_a.public_dns }
}

output "load-balancer" {
  value = aws_lb.load-balancer.dns_name
}
