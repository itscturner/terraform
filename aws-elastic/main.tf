#############################################
# VPC
#############################################

resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr

  enable_dns_support = true

  enable_dns_hostnames = true


  tags = {

    Name = "${var.project_name}-vpc"

  }

}



#############################################
# Internet Gateway
#############################################

resource "aws_internet_gateway" "main" {

  vpc_id = aws_vpc.main.id


  tags = {

    Name = "${var.project_name}-igw"

  }

}



#############################################
# Public Subnets - 3 Availability Zones
#############################################

resource "aws_subnet" "public" {

  count = length(var.availability_zones)


  vpc_id = aws_vpc.main.id


  cidr_block = var.public_subnet_cidrs[count.index]


  availability_zone = var.availability_zones[count.index]


  map_public_ip_on_launch = true


  tags = {

    Name = "${var.project_name}-public-${var.availability_zones[count.index]}"

    Tier = "public"

  }

}



#############################################
# Private Subnets - 3 Availability Zones
#############################################

resource "aws_subnet" "private" {

  count = length(var.availability_zones)


  vpc_id = aws_vpc.main.id


  cidr_block = var.private_subnet_cidrs[count.index]


  availability_zone = var.availability_zones[count.index]


  tags = {

    Name = "${var.project_name}-private-${var.availability_zones[count.index]}"

    Tier = "private"

  }

}



#############################################
# Public Route Tables
#############################################

resource "aws_route_table" "public" {

  count = length(var.availability_zones)


  vpc_id = aws_vpc.main.id


  route {

    cidr_block = "0.0.0.0/0"


    gateway_id = aws_internet_gateway.main.id

  }


  tags = {

    Name = "${var.project_name}-public-route-${var.availability_zones[count.index]}"

  }

}



resource "aws_route_table_association" "public" {

  count = length(var.availability_zones)


  subnet_id = aws_subnet.public[count.index].id


  route_table_id = aws_route_table.public[count.index].id

}



#############################################
# NAT Gateway Per Availability Zone
#############################################

resource "aws_eip" "nat" {

  count = length(var.availability_zones)


  domain = "vpc"


  tags = {

    Name = "${var.project_name}-nat-eip-${var.availability_zones[count.index]}"

  }

}



resource "aws_nat_gateway" "main" {

  count = length(var.availability_zones)


  allocation_id = aws_eip.nat[count.index].id


  subnet_id = aws_subnet.public[count.index].id


  tags = {

    Name = "${var.project_name}-nat-${var.availability_zones[count.index]}"

  }


  depends_on = [

    aws_internet_gateway.main

  ]

}



#############################################
# Private Route Tables
#############################################

resource "aws_route_table" "private" {

  count = length(var.availability_zones)


  vpc_id = aws_vpc.main.id


  route {

    cidr_block = "0.0.0.0/0"


    nat_gateway_id = aws_nat_gateway.main[count.index].id

  }


  tags = {

    Name = "${var.project_name}-private-route-${var.availability_zones[count.index]}"

  }

}



resource "aws_route_table_association" "private" {

  count = length(var.availability_zones)


  subnet_id = aws_subnet.private[count.index].id


  route_table_id = aws_route_table.private[count.index].id

}



#############################################
# IAM Role For Elasticsearch Nodes
#############################################

resource "aws_iam_role" "ec2" {

  name = "${var.project_name}-ec2-role"


  assume_role_policy = jsonencode({

    Version = "2012-10-17"


    Statement = [

      {

        Effect = "Allow"


        Principal = {

          Service = "ec2.amazonaws.com"

        }


        Action = "sts:AssumeRole"

      }

    ]

  })

}



#############################################
# IAM Policy
#############################################

resource "aws_iam_role_policy" "ec2" {

  name = "${var.project_name}-ec2-policy"


  role = aws_iam_role.ec2.id



  policy = jsonencode({

    Version = "2012-10-17"


    Statement = [

      {

        Effect = "Allow"


        Action = [

          "ec2:DescribeInstances",

          "ec2:DescribeVolumes",

          "ec2:DescribeTags"

        ]


        Resource = "*"

      }

    ]

  })

}



#############################################
# IAM Instance Profile
#############################################

resource "aws_iam_instance_profile" "ec2" {

  name = "${var.project_name}-instance-profile"


  role = aws_iam_role.ec2.name

}



#############################################
# Security Groups
#############################################

resource "aws_security_group" "nodes" {

  for_each = local.security_groups


  name = each.value.name


  description = "Security group for ${each.key} Elasticsearch nodes"


  vpc_id = aws_vpc.main.id



  dynamic "ingress" {

    for_each = each.value.ingress


    content {

      description = ingress.value.description


      from_port = ingress.value.from_port


      to_port = ingress.value.to_port


      protocol = ingress.value.protocol


      cidr_blocks = [

        ingress.value.cidr

      ]

    }

  }



  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"


    cidr_blocks = [

      "0.0.0.0/0"

    ]

  }



  tags = {

    Name = each.value.name

  }

}



#############################################
# Amazon Linux AMI Lookup
#############################################

data "aws_ami" "amazon_linux" {

  most_recent = true


  owners = [

    "amazon"

  ]



  filter {

    name = "name"


    values = [

      "al2023-ami-*-x86_64"

    ]

  }



  filter {

    name = "virtualization-type"


    values = [

      "hvm"

    ]

  }

}



#############################################
# Elasticsearch EC2 Module
#############################################

module "ec2" {

  source = "./modules/ec2"



  instances = local.instances



  /*
    Pass all private subnets.

    The EC2 module selects the subnet
    using each instance's subnet_index.
  */

  subnet_ids = aws_subnet.private[*].id



  ami = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id



  key_name = var.key_name



  instance_profile = aws_iam_instance_profile.ec2.name



  security_groups = {

    master = aws_security_group.nodes["master"].id

    data   = aws_security_group.nodes["data"].id

    kibana = aws_security_group.nodes["kibana"].id

  }



  root_volume_size = var.root_volume_size

}
