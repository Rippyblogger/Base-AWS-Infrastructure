variable "vpc_cidr_block" {
  type = string
}

variable "region" {
  type = string
}

variable "public_subnets" {
  type = map(string)
}

variable "private_subnets" {
  type = map(string)
}
