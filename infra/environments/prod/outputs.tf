# Copy these values into GitHub (Settings -> Secrets and variables -> Actions -> Variables)
# and into deploy/helm/taskboard/values-prod.yaml. See PROJECT.md, Phase B3.

output "cluster_name" {
  value = module.eks.cluster_name
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "backend_target_group_arn" {
  value = module.backend_alb.target_group_arn
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.db.name
}

output "frontend_bucket" {
  value = module.static_site.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.static_site.distribution_id
}

output "app_url" {
  value = "https://${module.static_site.domain_name}"
}

output "github_deploy_role_arn" {
  value = module.github_deploy_role.arn
}
