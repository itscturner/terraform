# providers.tf - AWS Elastic

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
