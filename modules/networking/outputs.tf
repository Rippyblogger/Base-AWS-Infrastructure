output "private_subnets" {
  value = [for k, v in aws_subnet.private_subnets: v.id]
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}