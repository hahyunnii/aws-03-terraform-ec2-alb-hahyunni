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
  # The region is passed in as a variable so students can reuse the same example in another lab region.
  region = var.aws_region
}
