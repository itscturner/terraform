# data.tf - AWS Elastic

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
