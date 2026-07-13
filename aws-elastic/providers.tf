# providers.tf - AWS Elastic

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
