variable "name" {
  description = "Name of the project Terraform is creating."
  type        = string
  default     = "elastic"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources into."
  default     = "us-east-1"
}

variable "instance_role" {
  type        = string
  description = "The role of the EC2 instance being created."
#  default     = "us-east-1"
}

variable "instance_count" {
  type        = number
  description = "The dynamic number of EC2 instances to provision."
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "The type of EC2 instance to provision."
  default     = "t3.micro"
}
