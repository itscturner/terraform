# main.tf - AWS Elastic

# ----- S3 -----

# Generate unique string suffix for S3 global uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Private S3 Storage Bucket
resource "aws_s3_bucket" "elasticsearch_storage" {
  bucket        = "elasticsearch-shared-storage-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "Elasticsearch Shared Storage"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "private_block" {
  bucket                  = aws_s3_bucket.elasticsearch_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----- IAM -----

# IAM Configurations
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "elasticsearch-ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "elasticsearch-s3-bucket-access-policy"
  role = aws_iam_role.ec2_s3_access_role.id

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
          aws_s3_bucket.elasticsearch_storage.arn,
          "${aws_s3_bucket.elasticsearch_storage.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "elasticsearch-ec2-instance-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

# ----- Application Load Balancer Infrastructure -----

# Security Group for the Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "sg-elasticsearch-alb-${var.environment}"
  description = "Allows public web access to the Kibana frontend"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name        = "sg-elasticsearch-alb"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_alb" "kibana_alb" {
  name               = "alb-kibana-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name        = "alb-kibana"
    Environment = var.environment
  }
}

# ALB Target Group pointing to Kibana ports
resource "aws_lb_target_group" "kibana_tg" {
  name     = "tg-kibana-${var.environment}"
  port     = 5601
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/status" # Kibana standard status endpoint
    port                = "5601"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# HTTP Listener forwarding traffic to the Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.kibana_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana_tg.arn
  }
}

# ----- EC2 -----

module "ec2" {
  source   = "./modules/ec2"
  for_each = local.node_roles

  cluster_type         = each.key
  instance_type        = each.value.instance_type
  min_size             = each.value.min_size
  max_size             = each.value.max_size
  desired_capacity     = each.value.desired_capacity
  ingress_rules        = each.value.ingress
  egress_rules         = each.value.egress
  ami_id               = data.aws_ami.rhel8.id
  subnet_ids           = data.aws_subnets.default.ids
  vpc_id               = data.aws_vpc.default.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  environment          = var.environment

  # Explicitly link Kibana ASG to the ALB Target Group
  target_group_arns = each.key == "kibana" ? [aws_lb_target_group.kibana_tg.arn] : []
}

# ----- ANSIBLE -----

data "aws_instances" "master_nodes" {
  instance_tags        = {
    Role = "elasticsearch-master"
    Environment = var.environment
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [module.ec2]
}

data "aws_instances" "data_nodes" {
  instance_tags        = {
    Role = "elasticsearch-data"
    Environment = var.environment
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [module.ec2]
}

data "aws_instances" "kibana_nodes" {
  instance_tags        = {
    Role = "kibana"
    Environment = var.environment
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [module.ec2]
}

resource "ansible_group" "all" {
  name = "all"
  variables = {
    ansible_user      = "ec2-user"
    shared_s3_bucket  = aws_s3_bucket.elasticsearch_storage.id
    target_aws_region = var.aws_region
  }
}

resource "ansible_host" "master_hosts" {
  for_each = toset(data.aws_instances.master_nodes.private_ips)
  name     = each.value
  groups   = ["elasticsearch-master"]
}

resource "ansible_host" "data_hosts" {
  for_each = toset(data.aws_instances.data_nodes.private_ips)
  name     = each.value
  groups   = ["elasticsearch-data"]
}

resource "ansible_host" "kibana_hosts" {
  for_each = toset(data.aws_instances.kibana_nodes.private_ips)
  name     = each.value
  groups   = ["kibana"]
}

resource "aws_s3_object" "upload_state_inventory" {
  bucket       = aws_s3_bucket.elasticsearch_storage.id
  key          = "ansible/inventory_summary.json"
  content_type = "application/json"

  content = jsonencode({
    metadata = {
      generation_region = var.aws_region
      environment       = var.environment
      s3_storage_source = aws_s3_bucket.elasticsearch_storage.id
    }
    groups = {
      elasticsearch_master = data.aws_instances.master_nodes.private_ips
      elasticsearch_data   = data.aws_instances.data_nodes.private_ips
      kibana               = data.aws_instances.kibana_nodes.private_ips
    }
  })
}
