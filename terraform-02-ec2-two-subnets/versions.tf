terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # AWS credentials are intentionally not declared here.
  # In AWS Academy, Terraform should read AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
  # and AWS_SESSION_TOKEN from the shell environment.
  # Reuse the same provider structure as Example 01 so students can compare files easily.
  region = var.aws_region
}
