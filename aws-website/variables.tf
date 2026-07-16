# variables.tf - AWS Website

variable "aws_region" {
  description = "The AWS geographic region where all resources will deploy."
  type        = string
  default     = "us-west-1"
}

variable "s3_bucket_name" {
  description = "The name of the AWS S3 bucket."
  type        = string
  default     = "my-unique-s3-bucket-name"
}
