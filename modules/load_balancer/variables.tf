variable "private_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "lb_logs_bucket_name" {
  type = string
}
