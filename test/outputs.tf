output "s3_bucket_name" {
  value       = aws_s3_bucket.shared_bucket.id
  description = "The globally unique name of the shared S3 bucket."
}

output "frontend_node_public_ip" {
  value       = module.ec2.frontend_node_public_ip
  description = "Public IP of Node 1, accessible externally on port 5601."
}

output "node_details" {
  value       = module.ec2.node_details
  description = "List of node deployment details demonstrating high availability."
}
