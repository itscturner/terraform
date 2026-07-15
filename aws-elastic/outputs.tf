# outputs.tf - AWS Elastic

output "all_node_instance_ids" {
  description = "A grouped mapping of all created EC2 Instance IDs by their role."
  value = {
    for role, execution_block in module.ec2 : role => execution_block.instance_ids
  }
}

output "elasticsearch_master_ips" {
  description = "Private IP addresses assigned to the Elasticsearch Master nodes."
  value       = try(module.ec2["elasticsearch-master"].private_ips, [])
}

output "elasticsearch_data_ips" {
  description = "Private IP addresses assigned to the Elasticsearch Data nodes."
  value       = try(module.ec2["elasticsearch-data"].private_ips, [])
}

output "elasticsearch_alb_dns_name" {
  description = "The internal DNS endpoint to route Elasticsearch HTTP data client traffic to."
  value       = aws_lb.elasticsearch_internal_alb.dns_name
}

output "elasticsearch_api_endpoint" {
  description = "The internal URL for Elasticsearch API data ingestion."
  value       = "http://${aws_route53_record.elasticsearch_api_dns.name}"
}

output "elasticsearch_snapshot_bucket_arn" {
  description = "The target AWS Resource Name tracking your production backup bucket cluster."
  value       = aws_s3_bucket.elastic_snapshots.arn
}

output "kibana_ips" {
  description = "Private IP addresses assigned to the Kibana nodes."
  value       = try(module.ec2["kibana"].private_ips, [])
}

output "kibana_alb_dns_name" {
  description = "The internal DNS endpoint utilized by end-users to load the Kibana UI."
  value       = aws_lb.kibana_internal_alb.dns_name
}

output "kibana_endpoint" {
  description = "The internal URL to access the Kibana UI."
  value       = "http://${aws_route53_record.kibana_dns.name}"
}
