locals {
  first_public_subnet_key = keys(var.public_subnets)[0]
}