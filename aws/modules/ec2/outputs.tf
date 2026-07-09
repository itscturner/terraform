output "instance_ids" {
  description = "EC2 Instance IDs"
  value = aws_instance.servers[*].id
}
