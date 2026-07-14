#############################################
# EC2 Instances
#############################################

resource "aws_instance" "this" {

  for_each = var.instances


  ami = var.ami


  instance_type = each.value.instance_type


  /*
    Select subnet based on subnet_index.

    Example:
    master-1 -> subnet 0
    master-2 -> subnet 1
    master-3 -> subnet 2
  */

  subnet_id = var.subnet_ids[each.value.subnet_index]



  key_name = var.key_name



  iam_instance_profile = var.instance_profile



  vpc_security_group_ids = [
    var.security_groups[each.value.node_type]
  ]



  root_block_device {

    volume_type = "gp3"

    volume_size = var.root_volume_size

    encrypted = true

  }



  user_data = <<-EOF
              #!/bin/bash

              hostnamectl set-hostname ${each.value.name}

              echo "ROLE=${each.value.role}" > /etc/elasticsearch-node-role

              echo "NODE_TYPE=${each.value.node_type}" >> /etc/elasticsearch-node-role

              EOF



  tags = {

    Name = each.value.name

    Role = each.value.role

    NodeType = each.value.node_type

    AvailabilityZone = var.subnet_ids[each.value.subnet_index]

  }

}



#############################################
# Elasticsearch Data Volumes
#############################################

resource "aws_ebs_volume" "data" {

  for_each = var.instances



  availability_zone = aws_instance.this[each.key].availability_zone



  size = each.value.volume_size



  type = "gp3"



  encrypted = true



  tags = {

    Name = "${each.value.name}-data"

    Role = each.value.role

  }

}



#############################################
# Attach Data Volumes
#############################################

resource "aws_volume_attachment" "data" {

  for_each = var.instances



  device_name = "/dev/sdf"



  volume_id = aws_ebs_volume.data[each.key].id



  instance_id = aws_instance.this[each.key].id

}
