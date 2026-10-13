variable "name" {
  type = string
}

variable "force_delete" {
  description = "Allow terraform destroy to delete the repository even if it contains images"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
