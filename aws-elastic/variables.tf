# variables.tf - AWS Elastic

variable "aws_region" {
  description = "The AWS geographic region where all resources will deploy."
  type        = string
  default     = "us-west-1"
}

variable "aws_access_key" {
  description = "The AWS Access Key ID utilized to authenticate API requests."
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "The AWS Secret Access Key utilized to authenticate API requests."
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "The public openSSH key text injected into instances at boot for admin login."
  type        = string
  #default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
}

variable "vpc_cidr" {
  description = "The primary IPv4 CIDR allocation block for the isolated network stack."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "The isolated internal subnet CIDR slices matching the dynamic AZs."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_domain_name" {
  description = "The custom private domain name used for internal cluster routing."
  type        = string
  default     = "elastic.internal"
}

variable "snapshot_bucket_name" {
  description = "The globally unique name of the S3 bucket used for Elastic cluster snapshot storage."
  type        = string
  default     = "elastic-snapshots" 
}

variable "elasticsearch_master_instance_type" {
  description = "EC2 instance type for the Elasticsearch Master nodes."
  type        = string
  default     = "t3.micro" #"c6i.large" 
}

variable "elasticsearch_master_instance_count" {
  description = "EC2 instance count for the Elasticsearch Master nodes."
  type        = number
  default     = 3 
}

variable "elasticsearch_data_instance_type" {
  description = "EC2 instance type for the Elasticsearch Data nodes."
  type        = string
  default     = "t3.micro" #"r6i.xlarge"
}

variable "elasticsearch_data_instance_count" {
  description = "EC2 instance count for the Elasticsearch Data nodes."
  type        = number
  default     = 3 
}

variable "kibana_instance_type" {
  description = "EC2 instance type for the Kibana nodes."
  type        = string
  default     = "t3.micro" #"t3.medium" 
}

variable "kibana_instance_count" {
  description = "EC2 instance count for the Kibana nodes."
  type        = number
  default     = 1
}

variable "ansible_ssh_user" {
  description = "The SSH login user Ansible should use to connect to the provisioned nodes."
  type        = string
  default     = "ec2-user"
}
