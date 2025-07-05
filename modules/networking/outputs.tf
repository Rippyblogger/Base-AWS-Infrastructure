output "private_subnets" {
  value = [for k, v in aws_subnet.private_subnets: v.id]
}
