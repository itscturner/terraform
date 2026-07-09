data "aws_ami" "rhel8_latest" {

  most_recent = true

  owners = ["309956199498"]

  filter {
    name   = "name"

    values = ["RHEL-8*"]
  }
}

##########

data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {

    name   = "name"

    values = ["al2023-ami-*x86_64"]

  }

}

##########

resource "aws_instance" "servers" {

  count = var.instance_count

  #ami = data.aws_ami.rhel8_latest.id
  ami = data.aws_ami.amazon_linux.id

  instance_type = var.instance_type

  subnet_id = var.subnet_id

  vpc_security_group_ids = [
    var.security_group_id
  ]

  iam_instance_profile = var.instance_profile

  tags = {
    Name = "server-${count.index}"
  }
}

