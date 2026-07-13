AWS Elastic
===========

This repository contains a modularized, production-grade Terraform framework that provisions a highly available and auto-scaling Elasticsearch and Kibana cluster on Amazon Web Services (AWS). 

The infrastructure runs on the latest **Red Hat Enterprise Linux 8 (RHEL 8)** AMI, uses **Auto Scaling Groups (ASGs)** for zero-downtime rolling updates, and features a cloud-native link with **Ansible** using the official Terraform Ansible Provider.

---

## Architecture

```text
                      [ Public Internet ]
                              │
                              ▼ (Port 80)
                ┌───────────────────────────┐
                │ Application Load Balancer │
                └─────────────┬─────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼ (Subnet A)        ▼ (Subnet B)        ▼ (Subnet C)
     ┌───────────┐       ┌───────────┐       ┌───────────┐
     │  Kibana   │       │  Kibana   │       │  Kibana   │  ◄── [ Kibana ASG ]
     └─────┬─────┘       └─────┬─────┘       └─────┬─────┘
           │                   │                   │
           └───────────────────┼───────────────────┘
                               ▼ (Ports 9200/9300 / Private Network Only)
    ┌─────────────────────────────────────────────────────────┐
    │  [ ES Master ASG ]  ──►  elasticsearch-master nodes     │
    │  [ ES Data ASG ]    ──►  elasticsearch-data nodes       │
    └──────────────────────────┬──────────────────────────────┘
                               │
                               ▼ (Secure IAM Role Policy)
                ┌───────────────────────────┐
                │ Private S3 Backup Storage │
                └───────────────────────────┘
```

### Core Architecture Components
* **Dynamic Auto Scaling Groups (ASGs)**: Automatically balances and distributes nodes across multiple Availability Zones (AZs) for high availability and automated instance recovery.
* **Elasticsearch Master Nodes**: Dedicated tier handling cluster state orchestration and consensus tracking.
* **Elasticsearch Data Nodes**: Dedicated data nodes managing index manipulation, storage shards, and heavy query crunching.
* **Kibana Nodes**: High-availability frontend presentation layer registered dynamically behind a regional ALB.
* **Application Load Balancer (ALB)**: Manages public/internal application ingestion, routing client inquiries on port `80` cleanly into Kibana pools running over port `5601`.
* **Shared Storage**: Secure, decoupled, private S3 storage engine dynamically provisioned with automated public access blocks, targeted for data snapshots and backups.
* **Ansible Integration**: Integrates the native `ansible/ansible` provider. It registers instances directly into the Terraform state file, allowing Ansible to query your live layout via dynamic inventory plugins without writing fragile text configuration templates.

---

## Project Structure

```text
aws-elastic/
├── data.tf               # Dynamic data collection (Latest RHEL 8 AMI, VPC info, subnets, AZs)
├── locals.tf             # Node configurations grouped by role (Counts, instance types, network rules)
├── main.tf               # Central backbone config (S3 bucket, IAM profiles, ALB, and module injection)
├── providers.tf          # AWS and Ansible Provider definitions and version constraints
├── variables.tf          # Global configuration variable switches
├── outputs.tf            # Structured cluster entry point diagnostics and endpoint configurations
├── inventory.yml         # Dynamic inventory plugin entry point configuration for Ansible
└── modules/
    └── ec2/              # Reusable Auto Scaling Group & Launch Template cluster module engines
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Configuration Management (`locals.tf`)

All scale bounds, pricing-tier controls, and protocol firewalls are isolated inside `locals.tf`. The node properties are grouped cleanly within respective `node_roles` schemas:

```hcl
locals {
  node_roles = {
    elasticsearch-master = {
      instance_type    = "t3.medium"
      desired_capacity = 3
      min_size         = 3
      max_size         = 3
      ingress          = [ ... ]
      egress           = [ ... ]
    }
    elasticsearch-data   = { ... }
    kibana               = { ... }
  }
}
```

---

## Prerequisites

Before deploying the pipeline, ensure your runtime interface satisfies the following conditions:
* **Terraform CLI**: Installed version `>= 1.5.0`.
* **Ansible**: Installed alongside the official Terraform provider engine collection.
* **Default VPC Subnets**: The `data.tf` file leverages the AWS default VPC configuration mapping. Ensure the default VPC has active, internet-accessible subnet definitions spanning multiple Availability Zones.

---

## Deployment Playbook

Follow these commands chronologically to initialize, inspect, and safely implement the cluster layout:

### 1. Initialize Working Directory
Downloads external lock dependencies, prepares system directories, and initiates the core module links.
```bash
terraform init
```

### 2. Verify State and Resource Execution Maps
Performs a semantic compilation check. This outputs exactly what infrastructure will be created, modified, or safely recycled without causing drift.
```bash
terraform plan
```

### 3. Build Cluster Resources
Deploys the infrastructure to your AWS account. Review the generation blueprint and type `yes` when prompted.
```bash
terraform apply
```

---

## Configuration Engine Automation (`Ansible Workflow`)

This project removes the need for flat, manual text `.ini` cluster configurations. Instead, it relies on the `cloud.terraform` inventory orchestration layout.

### 1. Install Required Community Collection
Ensure your local terminal runner has the mandatory plugin package library pulled:
```bash
ansible-galaxy collection install cloud.terraform
```

### 2. Inspect Live Inventory Map
To verify your active environment mappings, cluster groups, and globally mapped variable schemas (like target regions and S3 shared storage identifiers) fetched from state data, use the following operational hook:
```bash
ansible-inventory -i inventory.yml --graph
```

### 3. Run Configuration Playbooks
Execute your configuration playbooks over the live infrastructure map:
```bash
ansible-playbook -i inventory.yml site.yml
```

---

## Operational Guide

### How to Scale Nodes (Up or Down)
To change cluster size capacity settings (e.g., adding more data nodes to cope with storage metrics):
1. Open `locals.tf`.
2. Locate the specific `node_role` block (e.g., `elasticsearch-data`).
3. Modify the value for `desired_capacity`.
4. Run `terraform apply` to apply the scaling changes dynamically.

### Understanding the Zero-Downtime Rolling Update Strategy
The underlying module implements an `instance_refresh` control block that manages software patches and base image rollouts safely.

Whenever a new RHEL 8 AMI is captured dynamically by the `data.aws_ami.rhel8` lookup engine:
1. The system updates the background Launch Template properties.
2. The ASG flags the active fleet nodes as out-of-date.
3. The cluster begins a **Rolling Update**, maintaining a minimum of **50% of the nodes online and healthy** (`min_healthy_percentage = 50`) at all times.
4. The system updates nodes sequentially. It enforces a **300-second warm-up delay** between instance teardowns, allowing Elastic data replication and routing cycles to complete without data loss.

### Accessing the Kibana Frontend Interface
Once your deployment pipeline finishes successfully, the CLI returns a series of configuration variables. Use the provided entry point to load the Kibana platform:

```bash
# Retrieve the public ALB URL endpoint string directly from the terminal outputs
terraform output kibana_public_url
```

### Accessing the Topology Inventory Summary
A backup JSON map file tracking the private IP allocations across all node classes is compiled and securely pushed into your bucket upon every change. You can pull this for audit validation via the AWS CLI:

```bash
# Pull down the structural group map summary file
aws s3 cp \$(terraform output -raw s3_bucket_name)/ansible/inventory_summary.json ./
```

---

## Clean-up Playbook

When you no longer need this environment, you can remove all provisioned infrastructure. The S3 resource block contains a `force_destroy = true` argument, ensuring that all temporary cluster snapshots are purged cleanly without leaving orphan data chunks behind.

```bash
terraform destroy
```
