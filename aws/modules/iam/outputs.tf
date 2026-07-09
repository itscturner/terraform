output "instance_profile" {
  description = "IAM Instance Profile Name"
  value = aws_iam_instance_profile.profile.name
}
