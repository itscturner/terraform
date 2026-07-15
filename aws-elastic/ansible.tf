# ansible.tf - AWS Elastic

locals {
  ansible_node_groups = {
    for role, mod in module.ec2 : role => mod.private_ips
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    node_groups = local.ansible_node_groups
    ssh_user    = var.ansible_ssh_user
  })
}
