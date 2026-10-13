variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "secrets_manager_arns" {
  description = "Secrets that External Secrets may read"
  type        = list(string)
}

variable "lb_controller_chart_version" {
  type    = string
  default = "3.6.0"
}

variable "external_secrets_chart_version" {
  type    = string
  default = "2.12.0"
}

variable "tags" {
  type    = map(string)
  default = {}
}
