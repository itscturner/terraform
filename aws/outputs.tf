output "instances" {
  description = "EC2 Instance IDs"
  value       = module.ec2.instance_ids
}

output "bucket" {
  description = "S3 Bucket Name"
  value       = module.s3.bucket_name
}
