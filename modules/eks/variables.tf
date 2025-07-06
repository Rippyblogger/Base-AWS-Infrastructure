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

# variable "account_id" {
#   type = string
# }