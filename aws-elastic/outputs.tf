# outputs.tf - AWS Elastic

output "s3_bucket_name" {
  description = "The globally unique identifier for the shared S3 data bucket."
  value       = aws_s3_bucket.elasticsearch_storage.id
}

output "autoscaling_groups" {
  description = "Cluster Auto Scaling Group registration identifiers."
  value = {
    for type, mod in module.cluster_nodes : type => {
      name = mod.asg_name
      arn  = mod.asg_arn
    }
  } 
}

output "kibana_public_url" {
  description = "Public web address to connect to the Kibana interface."
  value       = "http://${aws_alb.kibana_alb.dns_name}"
}
