# variables.tf - AWS Elastic/EC2

variable "key_name" {
  description = "The target key pair identifier authorized to authenticate SSH terminal requests."
  type        = string
}

variable "node_role" {
  description = "The specific role of the node (e.g., elasticsearch-master, elasticsearch-data, kibana)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type to deploy."
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to deploy."
  type        = number
}

variable "ami_id" {
  description = "The latest RHEL 8 AMI ID."
  type        = string
}

variable "subnet_ids" {
  description = "The list of private subnet IDs distributed across multiple AZs."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Associated firewall security group IDs."
  type        = list(string)
}

variable "instance_profile" {
  description = "The IAM instance profile for cluster metadata access."
  type        = string
}

variable "root_volume_size" {
  description = "Size of the OS root disk in GiB."
  type        = number
}

variable "ebs_volume_size" {
  description = "Size of the dedicated secondary EBS data disk in GiB."
  type        = number
}

variable "ebs_iops" {
  description = "The amount of provisioned IOPS. Only valid for gp3, io1, and io2 volumes."
  type        = number
  default     = null
}

variable "ebs_throughput" {
  description = "The throughput to provision for a gp3 volume in MiB/s."
  type        = number
  default     = null
}
