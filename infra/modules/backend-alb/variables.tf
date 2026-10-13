variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "backend_port" {
  type    = number
  default = 8000
}

variable "origin_verify_secret" {
  description = "Secret header value that CloudFront sends and the ALB checks"
  type        = string
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
