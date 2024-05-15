output "load_balancer_dns_name" {
  value = "http://${aws_lb.quest_lb.dns_name}"
}