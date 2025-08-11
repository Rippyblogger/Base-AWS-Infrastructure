variable "deployment_name" {
  type = string
}
variable "env" {
  type = string
}

variable "replicas_count" {
  type = number
}

variable "app_name" {
  type = string
}

variable "image_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "oidc_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}
