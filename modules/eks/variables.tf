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