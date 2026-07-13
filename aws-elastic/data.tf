# data.tf - AWS Elastic

# Get the latest RHEL 8 AMI
data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat AWS Owner ID

  filter {
    name   = "name"
    values = ["RHEL-8.*_HVM-*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Dynamically gets active AZs in the current region for High Availability
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetches default VPC for demo simplification
data "aws_vpc" "default" {
  default = true
}

# Fetches default subnets to distribute EC2s across AZs
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
