# variables.tf - AWS Elastic

variable "aws_region" {
  description = "The AWS region to deploy all resources into."
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}
