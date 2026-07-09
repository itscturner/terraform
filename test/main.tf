resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { 
    Name = "${var.name}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count                   = min(3, length(data.aws_availability_zones.available.names))
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = {
    Name = "ha-cluster-public-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "${var.name}-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "${var.name}-public-route-table"
    }
}

resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_s3_bucket" "shared_bucket" {
  bucket_prefix = "ha-cluster-storage-"
  force_destroy = true
  tags          = {
    Name = "${var.name}-storage"
  }
}

module "ec2" {
  source = "./modules/ec2"
  
  name = var.name

  for_each = local.apps

  instance_role = each.value.instance_role
  instance_count  = each.value.instance_count
  instance_type   = each.value.instance_type
  ingress_port    = each.value.ingress_port

  vpc_id          = aws_vpc.main.id
  subnet_ids      = aws_subnet.public[*].id
  shared_s3_arn   = aws_s3_bucket.shared_bucket.arn
}
