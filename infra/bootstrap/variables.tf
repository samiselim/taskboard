variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "github_repository" {
  description = "Your repository as owner/name, e.g. alice/taskboard"
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique bucket name, e.g. taskboard-tfstate-<your-account-id>"
  type        = string
}
