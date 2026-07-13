# locals.tf - AWS Elastic

locals {
  node_roles = {
    elasticsearch-master = {
      instance_type    = "t3.medium"
      min_size         = 3
      max_size         = 3
      desired_capacity = 3
      ingress = [
        { from_port = 9200, to_port = 9200, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"] },
        { from_port = 9300, to_port = 9300, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"] },
        { from_port = 22,   to_port = 22,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
      ]
      egress = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
      ]
    }

    elasticsearch-data = {
      instance_type    = "t3.large"
      min_size         = 3
      max_size         = 10
      desired_capacity = 5
      ingress = [
        { from_port = 9200, to_port = 9200, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"] },
        { from_port = 9300, to_port = 9300, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"] }
      ]
      egress = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
      ]
    }

    kibana = {
      instance_type    = "t3.medium"
      min_size         = 2
      max_size         = 4
      desired_capacity = 2
      ingress = [
        # Allow internal cluster/VPC components and ALB communication
        { from_port = 5601, to_port = 5601, protocol = "tcp", cidr_blocks = ["10.0.0.0/8", "0.0.0.0/0"] }
      ]
      egress = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
      ]
    }
  }
}
