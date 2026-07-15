# data.tf - AWS Elastic

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "rhel8_latest" {
  most_recent = true
  owners      = ["309956199498"] 

  filter {
    name   = "name"
  #  values = ["RHEL-8.*_HVM-*-x86_64-*Hourly*"]
    values = ["RHEL-8.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "amazon_linux_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
