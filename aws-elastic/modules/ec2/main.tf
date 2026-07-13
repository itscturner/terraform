# main.tf - AWS Elastic/EC2

# Tier-specific Security Group
resource "aws_security_group" "sg" {
  name        = "sg-${var.cluster_type}-${var.environment}"
  description = "Managed Firewall for ${var.cluster_type} ASG instances."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name        = "sg-${var.cluster_type}"
    Environment = var.environment
  }
}

# Launch Template describing ASG Node Blueprint
resource "aws_launch_template" "asg_template" {
  name_prefix   = "lt-${var.cluster_type}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_type}-asg-node"
      Role        = var.cluster_type
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group ensuring HA and dynamic capacity controls
resource "aws_autoscaling_group" "asg" {
  name_prefix         = "asg-${var.cluster_type}-"
  vpc_zone_identifier = var.subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Binds target group tracking definitions dynamically if provided
  target_group_arns = var.target_group_arns

  launch_template {
    id      = aws_launch_template.asg_template.id
    version = "$Latest"
  }

  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = 300
  force_delete              = true

  # --- Rolling Update Strategy Configuration ---
  instance_refresh {
    strategy = "Rolling"
    preferences {
      # Ensures at least 50% of your cluster stays healthy and online during the update
      min_healthy_percentage = 50
      
      # Number of seconds to wait after an instance comes online before starting the next one
      instance_warmup = 300
    }
    triggers = ["tag"] # Re-triggers update lifecycle changes if properties drift
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
