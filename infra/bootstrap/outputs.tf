output "state_bucket" {
  value = aws_s3_bucket.state.id
}

output "infra_role_arn" {
  description = "Save as the GitHub variable AWS_INFRA_ROLE_ARN"
  value       = module.infra_role.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
