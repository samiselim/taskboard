variable "name" {
  type = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the frontend files"
  type        = string
}

variable "api_origin_domain" {
  description = "DNS name of the backend ALB (target of /api/*)"
  type        = string
}

variable "origin_verify_secret" {
  description = "Secret header value sent to the ALB"
  type        = string
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
