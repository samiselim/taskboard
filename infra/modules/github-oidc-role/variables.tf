variable "name" {
  type = string
}

variable "oidc_provider_arn" {
  description = "ARN of the token.actions.githubusercontent.com OIDC provider"
  type        = string
}

variable "subjects" {
  description = "Allowed 'sub' claims, e.g. repo:my-org/my-repo:ref:refs/heads/main"
  type        = list(string)
}

variable "policy_json" {
  description = "Inline policy (least privilege)"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
