resource "aws_security_group" "cluster_sg" {
  name        = "${var.name}-security-group"
  description = "Controls cross-AZ communication and external access"
  vpc_id      = var.vpc_id




#  ingress {
#    description = "Internal cross-AZ cluster communication"
#    from_port   = 9300
#    to_port     = 9300
#    protocol    = "tcp"
#    self        = true
#  }

#  ingress {
#    description = "External web UI access"
#    from_port   = 5601
#    to_port     = 5601
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }



  ingress {
    from_port   = var.ingress_port
    to_port     = var.ingress_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }





  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-cluster-security-group"
  }
}




data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["://amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_s3_role" {
  name               = "${var.name}-ec2-s3-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "${var.name}-s3-bucket-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.shared_s3_arn,
          "${var.shared_s3_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2_s3_role.name
}




data "aws_ami" "rhel8_latest" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat AWS Account ID

  filter {
    name   = "name"
    values = ["RHEL-8.*_HVM-*-x86_64-*Hourly*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}





resource "aws_instance" "node" {
  count = var.instance_count

  ami                    = data.aws_ami.rhel8_latest.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]

  # Dynamic round-robin mapping across the list of subnets passed into the module
  subnet_id = var.subnet_ids[count.index % length(var.subnet_ids)]

  tags = {
    Name = "${var.instance_role}-${count.index + 1}"
    Role = var.instance_role
  }
}


