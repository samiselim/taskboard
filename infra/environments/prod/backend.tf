# Remote state in the bucket created by infra/bootstrap.
# The bucket name is passed at init time:
#   terraform init -backend-config="bucket=<state_bucket>"
terraform {
  backend "s3" {
    key          = "taskboard/prod/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true # S3-native state locking (no DynamoDB table needed)
  }
}
