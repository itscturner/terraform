variable "instances" {
  description = "Map of Elasticsearch nodes to create"

  type = map(object({

    name = string

    role = string

    node_type = string

    instance_type = string

    volume_size = number

    subnet_index = number

    ingress = list(object({

      description = string

      from_port = number

      to_port = number

      protocol = string

      cidr = string

    }))

  }))
}



variable "ami" {

  description = "AMI ID used for EC2 instances"

  type = string

}



variable "subnet_ids" {

  description = "List of private subnet IDs across availability zones"

  type = list(string)

}



variable "instance_profile" {

  description = "IAM instance profile attached to EC2 instances"

  type = string

}



variable "security_groups" {

  description = "Security groups mapped by node type"

  type = map(string)

}



variable "key_name" {

  description = "EC2 key pair name"

  type = string

  default = null

}



variable "root_volume_size" {

  description = "Root EBS volume size"

  type = number

  default = 50

}
