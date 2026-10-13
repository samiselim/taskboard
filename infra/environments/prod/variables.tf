variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "taskboard"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "github_repository" {
  description = "Your repository as owner/name, e.g. alice/taskboard"
  type        = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "admin_principal_arns" {
  description = "IAM users/roles (e.g. your own) that get admin access to the cluster"
  type        = list(string)
  default     = []
}
