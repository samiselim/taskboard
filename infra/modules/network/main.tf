data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# VPC with public subnets (ALB, NAT) and private subnets (EKS nodes, pods)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = var.name
  cidr = var.cidr
  azs  = local.azs

  private_subnets = [for i, _ in local.azs : cidrsubnet(var.cidr, 4, i)]      # 10.0.0.0/20, 10.0.16.0/20
  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.cidr, 8, 48 + i)] # 10.0.48.0/24, 10.0.49.0/24

  enable_nat_gateway = true
  single_nat_gateway = true # one NAT gateway for the whole VPC: cheaper, not highly available

  # Tags used by the AWS Load Balancer Controller to discover subnets
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }

  tags = var.tags
}
