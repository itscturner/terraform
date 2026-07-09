


variable "name" {}

variable "ingress_port" {}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the security groups will be created."
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs to distribute instances across."
}

variable "shared_s3_arn" {
  type        = string
  description = "The ARN of the shared S3 bucket to authorize permissions for."
}

variable "instance_count" {
  type        = number
  description = "The dynamic number of EC2 instances to provision."
}

variable "instance_type" {
  type        = string
  description = "The hardware sizing for the EC2 instances."
}



variable "instance_role" {
  type        = string
  description = "INSTANCE ROLE"
#  default     = "us-east-1"
}
