# outputs.tf - AWS Website

output "website_url" {
  description = "The public URL of your static website"
  value       = aws_s3_bucket_website_configuration.website_config.website_endpoint
}
