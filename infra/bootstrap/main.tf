# Run ONCE from your laptop with your own AWS credentials (local state).
# Creates what the CI needs before it can run Terraform itself:
#   1) the S3 bucket that stores the Terraform state of environments/prod
#   2) the GitHub OIDC provider + the role the "infra" workflow assumes

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "taskboard", ManagedBy = "terraform", Stack = "bootstrap" }
  }
}

# ---- Terraform state bucket
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled" # lets you recover a previous state file
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---- GitHub OIDC
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Role used by .github/workflows/infra.yml (plan on PRs, apply on main after approval)
module "infra_role" {
  source = "../modules/github-oidc-role"

  name              = "taskboard-github-infra"
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  subjects = [
    "repo:${var.github_repository}:pull_request",
    "repo:${var.github_repository}:ref:refs/heads/main",
    "repo:${var.github_repository}:environment:infrastructure",
  ]
  # Terraform creates VPCs, EKS, IAM roles... A real company would narrow this down.
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
