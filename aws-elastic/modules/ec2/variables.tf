# variables.tf - AWS Elastic/EC2

variable "cluster_type" { type = string }

variable "instance_type" { type = string }

variable "min_size" { type = number }

variable "max_size" { type = number }

variable "desired_capacity" { type = number }

variable "ami_id" { type = string }

variable "vpc_id" { type = string }

variable "iam_instance_profile" { type = string }

variable "environment" { type = string }

variable "subnet_ids" { type = list(string) }

variable "target_group_arns" {
  description = "Optional ALB target groups to link directly into the ASG."
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}
