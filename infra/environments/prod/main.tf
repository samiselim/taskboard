data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ------------------------------------------------------------------ network + cluster
module "network" {
  source = "../../modules/network"

  name = local.name
  tags = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name         = local.name
  kubernetes_version   = var.kubernetes_version
  vpc_id               = module.network.vpc_id
  subnet_ids           = module.network.private_subnet_ids
  node_instance_types  = var.node_instance_types
  admin_principal_arns = var.admin_principal_arns
  tags                 = local.tags
}

# ------------------------------------------------------------------ backend image registry
module "ecr" {
  source = "../../modules/ecr"

  name = "${var.project}-backend"
  tags = local.tags
}

# ------------------------------------------------------------------ backend entry point (ALB)
resource "random_password" "origin_verify" {
  length  = 32
  special = false
}

module "backend_alb" {
  source = "../../modules/backend-alb"

  name                 = local.name
  vpc_id               = module.network.vpc_id
  vpc_cidr             = module.network.vpc_cidr
  public_subnet_ids    = module.network.public_subnet_ids
  origin_verify_secret = random_password.origin_verify.result
  tags                 = local.tags
}

# Let the ALB reach the backend pods (pods use the node security group with the VPC CNI)
resource "aws_vpc_security_group_ingress_rule" "alb_to_pods" {
  security_group_id            = module.eks.node_security_group_id
  referenced_security_group_id = module.backend_alb.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  description                  = "Backend ALB to TaskBoard pods"
}

# ------------------------------------------------------------------ frontend (S3 + CloudFront)
module "static_site" {
  source = "../../modules/static-site"

  name                 = local.name
  bucket_name          = "${local.name}-frontend-${data.aws_caller_identity.current.account_id}"
  api_origin_domain    = module.backend_alb.dns_name
  origin_verify_secret = random_password.origin_verify.result
  tags                 = local.tags
}

# ------------------------------------------------------------------ database credentials
resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project}/${var.environment}/database"
  recovery_window_in_days = 0 # allow immediate re-creation after destroy (lab setting)
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "taskboard"
    password = random_password.db.result
  })
}

# ------------------------------------------------------------------ role for the app workflows
module "github_deploy_role" {
  source = "../../modules/github-oidc-role"

  name              = "${local.name}-github-deploy"
  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn
  subjects = [
    "repo:${var.github_repository}:ref:refs/heads/main", # push images from main
    "repo:${var.github_repository}:ref:refs/tags/*",     # release workflow (promote image)
    "repo:${var.github_repository}:environment:production",
  ]

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:CompleteLayerUpload",
          "ecr:DescribeImages", "ecr:GetDownloadUrlForLayer", "ecr:InitiateLayerUpload",
          "ecr:PutImage", "ecr:UploadLayerPart",
        ]
        Resource = module.ecr.repository_arn
      },
      {
        Sid      = "FrontendUpload"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [module.static_site.bucket_arn, "${module.static_site.bucket_arn}/*"]
      },
      {
        Sid      = "CacheInvalidation"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
        Resource = module.static_site.distribution_arn
      },
    ]
  })

  tags = local.tags
}

# ------------------------------------------------------------------ cluster add-ons (LB Controller, External Secrets)
module "platform" {
  source = "../../modules/platform"

  cluster_name         = module.eks.cluster_name
  region               = var.region
  vpc_id               = module.network.vpc_id
  secrets_manager_arns = [aws_secretsmanager_secret.db.arn]
  tags                 = local.tags

  depends_on = [module.eks]
}
