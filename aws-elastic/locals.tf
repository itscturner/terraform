locals {

  /*
    Flatten Elasticsearch nodes into individual instances.

    Each instance receives an AZ index so the EC2 module
    can distribute nodes across the three availability zones.
  */

  instances = merge(
    [
      for node_type, node in local.node_roles :
      {
        for index in range(node.count) :

        "${node_type}-${index + 1}" = {

          name = "${node_type}-${index + 1}"

          role = node.role

          node_type = node_type

          instance_type = node.instance_type

          volume_size = node.volume_size

          ingress = node.ingress


          /*
            Distribute nodes evenly:

            master-1 -> AZ 0
            master-2 -> AZ 1
            master-3 -> AZ 2

            data-1 -> AZ 0
            data-2 -> AZ 1
            data-3 -> AZ 2
            etc.
          */

          subnet_index = index % length(var.availability_zones)

        }
      }
    ]...
  )



  /*
    Security groups remain unchanged.
    Each node type receives its own SG.
  */

  security_groups = {
    for node_type, node in local.node_roles :

    node_type => {

      name = "${var.project_name}-${node_type}-sg"

      ingress = node.ingress

    }
  }
}
