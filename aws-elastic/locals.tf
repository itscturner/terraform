# locals.tf - AWS Elastic

locals {
  node_roles = {
    "elasticsearch-master" = {
      instance_count = var.elasticsearch_master_instance_count
      instance_type  = var.elasticsearch_master_instance_type
      root_vol_size  = 30
      ebs_vol_size   = 50
      ebs_iops       = null # Uses AWS Default baseline (3000)
      ebs_throughput = null # Uses AWS Default baseline (125)
    }

    "elasticsearch-data" = {
      instance_count = var.elasticsearch_data_instance_count
      instance_type  = var.elasticsearch_data_instance_type
      root_vol_size  = 30
      ebs_vol_size   = 500
      ebs_iops       = 6000 # Scaled IOPS for high indexing rates
      ebs_throughput = 250  # Scaled Throughput (MB/s) for heavy shard recoveries
    }

    "kibana" = {
      instance_count = var.kibana_instance_count
      instance_type  = var.kibana_instance_type
      root_vol_size  = 30
      ebs_vol_size   = 20
      ebs_iops       = null # Uses AWS Default baseline (3000)
      ebs_throughput = null # Uses AWS Default baseline (125)
    }
  }
}
