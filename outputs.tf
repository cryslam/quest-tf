output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.subnet : s.cidr_block]
}

output "load_balancer_dns_name" {
  value = "http://${aws_lb.quest_lb.dns_name}"
}