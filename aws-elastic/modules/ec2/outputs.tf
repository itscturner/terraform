# outputs.tf - AWS Elastic/EC2

output "instance_ids" {
  description = "Unique AWS Resource identification tokens."
  value       = aws_instance.node[*].id
}

output "private_ips" {
  description = "Private IP endpoints of the provisioned nodes."
  value       = aws_instance.node[*].private_ip
}
