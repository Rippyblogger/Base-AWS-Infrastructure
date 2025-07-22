variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "node_group_name" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable capacity_type {
    type = string
}

variable "instance_types" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "alb_security_group_id" {
  type        = string
}

variable "instance_type" {
  type = string
}

variable "ecr_repo_name" {
  type = string
}
