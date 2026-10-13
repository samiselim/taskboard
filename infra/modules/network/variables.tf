variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones (EKS needs at least 2)"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags added to every resource"
  type        = map(string)
  default     = {}
}
