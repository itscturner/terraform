output "instances" {
  description = "Created EC2 instance information"

  value = {
    for name, instance in aws_instance.this :

    name => {

      id = instance.id

      private_ip = instance.private_ip

      public_ip = instance.public_ip

      role = instance.tags["Role"]

      instance_type = instance.instance_type

    }
  }
}


output "instance_ids" {
  description = "Map of node names to instance IDs"

  value = {
    for name, instance in aws_instance.this :
    name => instance.id
  }
}


output "private_ips" {
  description = "Map of node names to private IP addresses"

  value = {
    for name, instance in aws_instance.this :
    name => instance.private_ip
  }
}


output "ebs_volumes" {
  description = "Map of node names to attached EBS volume IDs"

  value = {
    for name, volume in aws_ebs_volume.data :
    name => volume.id
  }
}
