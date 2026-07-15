# main.tf - AWS Elastic/EC2

resource "aws_instance" "node" {
  count = var.instance_count

  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = element(var.subnet_ids, count.index)
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile = var.instance_profile
  key_name             = var.key_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -ex
              sleep 15
              TARGET_DISK="/dev/sdb"
              if [ ! -b "$TARGET_DISK" ] && [ -b "/dev/nvme1n1" ]; then
                TARGET_DISK="/dev/nvme1n1"
              fi
              if [ -b "$TARGET_DISK" ]; then
                if ! blkid "$TARGET_DISK"; then
                  mkfs -t ext4 "$TARGET_DISK"
                fi
                MOUNT_DIR="/mnt/elastic-data"
                mkdir -p "$MOUNT_DIR"
                DISK_UUID=$(blkid -o value -s UUID "$TARGET_DISK")
                if ! grep -q "$DISK_UUID" /etc/fstab; then
                  echo "UUID=$DISK_UUID $MOUNT_DIR ext4 defaults,nofail 0 2" >> /etc/fstab
                fi
                mount -a
              fi
              EOF

  tags = {
    Name = "elastic-${var.node_role}-node-${count.index + 1}"
    Role = var.node_role
  }
}

resource "aws_ebs_volume" "data_vol" {
  count             = var.instance_count
  availability_zone = aws_instance.node[count.index].availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  iops              = var.ebs_iops
  throughput        = var.ebs_throughput

  tags = {
    Name = "elastic-${var.node_role}-data-ebs-${count.index + 1}"
    Role = var.node_role
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count       = var.instance_count
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.data_vol[count.index].id
  instance_id = aws_instance.node[count.index].id
}
