output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc.id
}

output "public_subnet" {
  description = "Public Subnet"
  value       = aws_subnet.public.id
}

