locals {
  apps = {
    elasticsearch-master = {
      instance_role = "elasticsearch-master"
      instance_type = "t3.medium"
      instance_count = 3
      ingress_port = 9300
    }
    elasticsearch-data = {
      instance_role = "elasticsearch-data"
      instance_type = "r6i.xlarge"
      instance_count = 3
      ingress_port = 9300
    }
    kibana = {
      instance_role = "kibana"
      instance_type = "t3.small"
      instance_count = 1
      ingress_port = 5601
    }
  }
}
