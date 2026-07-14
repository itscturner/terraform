output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}


output "private_subnet_id" {
  description = "Private subnet ID where Elasticsearch nodes are deployed"
  value       = aws_subnet.private.id
}


output "elasticsearch_nodes" {
  description = "Elasticsearch EC2 instance information"
  value = {
    for name, instance in module.ec2.instances :
    name => {
      id         = instance.id
      private_ip = instance.private_ip
      role       = instance.role
    }
  }
}


output "kibana_url" {
  description = "Kibana access URL"
  value = length([
    for name, instance in module.ec2.instances :
    instance
    if instance.role == "kibana"
  ]) > 0 ? "http://<kibana-private-ip>:5601" : null
}


output "security_groups" {
  description = "Created security groups"
  value = {
    for name, sg in aws_security_group.nodes :
    name => sg.id
  }
}


output "iam_instance_profile" {
  description = "EC2 instance profile attached to nodes"
  value       = aws_iam_instance_profile.ec2.name
}
