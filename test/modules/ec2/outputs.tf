










output "frontend_node_public_ip" {
  value       = aws_instance.node[0].public_ip
  description = "Public IP of the primary frontend node mapping to external port 5601."
}


output "node_details" {
  value = [
    for i in range(var.instance_count) : {
      node_name  = "ha-cluster-node-${i + 1}"
      private_ip = aws_instance.node[i].private_ip
      subnet_id  = aws_instance.node[i].subnet_id
      az         = aws_instance.node[i].availability_zone
    }
  ]
  description = "List containing individual metadata metrics for the deployed compute cluster."
}


