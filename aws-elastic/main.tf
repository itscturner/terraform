# main.tf - AWS Elastic

resource "aws_key_pair" "ssh_key" {
  key_name   = "elastic-ssh-key"
  public_key = var.ssh_public_key
}

resource "aws_vpc" "elastic_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = {
    Name = "elastic-vpc"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.elastic_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = { 
    Name = "elastic-private-subnet-${data.aws_availability_zones.available.names[count.index]}" 
  }
}

resource "aws_security_group" "elasticsearch_alb_sg" {
  name        = "elastic-es-alb-sg"
  description = "Controls internal traffic access to the Elasticsearch ALB"
  vpc_id      = aws_vpc.elastic_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kibana_alb_sg" {
  name        = "elastic-kibana-alb-sg"
  description = "Controls internal web browser access to Kibana ALB"
  vpc_id      = aws_vpc.elastic_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elastic_sg" {
  name        = "elastic-sg"
  description = "Strict port configuration for ES and Kibana"
  vpc_id      = aws_vpc.elastic_vpc.id

  ingress {
    description = "Secure Shell (SSH) Access from Internal Network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] 
  }

  ingress {
    from_port = 9300
    to_port   = 9300
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticsearch_alb_sg.id]
  }

  ingress {
    from_port       = 5601
    to_port         = 5601
    protocol        = "tcp"
    security_groups = [aws_security_group.kibana_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "elastic-ec2-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ec2_discovery_policy" {
  name = "elastic-ec2-discovery-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "elastic-instance-profile"
  role = aws_iam_role.ec2_role.name
}

module "ec2" {
  source   = "./modules/ec2"
  for_each = local.node_roles

  node_role          = each.key
  instance_count     = each.value.instance_count
  ami_id             = data.aws_ami.rhel8_latest.id
  #ami_id             = data.aws_ami.amazon_linux_latest.id
  instance_type      = each.value.instance_type
  subnet_ids         = aws_subnet.private_subnets[*].id 
  security_group_ids = [aws_security_group.elastic_sg.id]
  instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name           = aws_key_pair.ssh_key.key_name 
  root_volume_size   = each.value.root_vol_size
  ebs_volume_size    = each.value.ebs_vol_size
  ebs_iops           = each.value.ebs_iops
  ebs_throughput     = each.value.ebs_throughput
}

resource "aws_lb" "elasticsearch_internal_alb" {
  name               = "elastic-es-alb"
  internal           = true 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elasticsearch_alb_sg.id]
  subnets            = aws_subnet.private_subnets[*].id
}

resource "aws_lb_target_group" "elasticsearch_data_tg" {
  name     = "es-data-nodes-tg"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = aws_vpc.elastic_vpc.id
  health_check {
    path     = "/" 
    port     = "9200"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "es_http_listener" {
  load_balancer_arn = aws_lb.elasticsearch_internal_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elasticsearch_data_tg.arn
  }
}

resource "aws_lb" "kibana_internal_alb" {
  name               = "elastic-kibana-alb"
  internal           = true 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kibana_alb_sg.id]
  subnets            = aws_subnet.private_subnets[*].id
}

resource "aws_lb_target_group" "kibana_tg" {
  name     = "kibana-nodes-tg"
  port     = 5601
  protocol = "HTTP"
  vpc_id   = aws_vpc.elastic_vpc.id
  health_check {
    path     = "/status" 
    port     = "5601"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "kibana_http_listener" {
  load_balancer_arn = aws_lb.kibana_internal_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana_tg.arn
  }
}

resource "aws_route53_zone" "private_zone" {
  name = var.private_domain_name
  vpc  { vpc_id = aws_vpc.elastic_vpc.id }
}

resource "aws_route53_record" "kibana_dns" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "kibana.${var.private_domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.kibana_internal_alb.dns_name
    zone_id                = aws_lb.kibana_internal_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "elasticsearch_api_dns" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "api.${var.private_domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.elasticsearch_internal_alb.dns_name
    zone_id                = aws_lb.elasticsearch_internal_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_s3_bucket" "elastic_snapshots" {
  bucket        = "${var.snapshot_bucket_name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "elastic_snapshots_block" {
  bucket                  = aws_s3_bucket.elastic_snapshots.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role_policy" "elastic_s3_snapshot_policy" {
  name   = "elastic-s3-snapshot-policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation"]
      Resource = [aws_s3_bucket.elastic_snapshots.arn, "${aws_s3_bucket.elastic_snapshots.arn}/*"]
    }]
  })
}
