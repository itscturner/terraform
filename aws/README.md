AWS
===

This repository contains a modularized, production-grade Terraform framework that provisions a highly available, and auto-scaling Elasticsearch and Kibana cluster on Amazon Web Services (AWS). 

The infrastructure is running on the latest Red Hat Enterprise Linux (RHEL) 8 AMIs, structured with strict security isolation rules, integrated with a rolling update strategy, and fronted by an Application Load Balancer (ALB).

---

## Project Structure

```
aws/
├── data.tf           # Dynamic data collection (Latest RHEL 8 AMI, VPC info, subnets, AZs)
├── locals.tf         # Node configurations grouped strictly by role (Counts, instance types, network rules)
├── main.tf           # Central backbone config (S3 bucket, IAM profiles, ALB, and module injection)
├── providers.tf      # AWS Provider definition and version constraints
├── variables.tf      # Global configuration variable switches
├── outputs.tf        # Structured cluster entry point diagnostics and endpoint configurations
└── modules/
    └── ec2_cluster/  # Reusable Auto Scaling Group & Launch Template cluster module engines
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Architecture Blueprint

```
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
                               ▼ (Ports 9200/9300)
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

---

### Core Components
* **Dynamic Auto Scaling Groups (ASGs)**: Distributed across multiple Availability Zones (AZs) for strict high availability.
* **Elasticsearch Master Nodes**: Dedicated tier handling cluster state orchestration and consensus tracking.
* **Elasticsearch Data Nodes**: Dedicated data nodes managing index manipulation, storage shards, and heavy query crunching.
* **Kibana Nodes**: High-availability frontend presentation layer registered dynamically behind a regional ALB.
* **Application Load Balancer**: Manages public/internal application ingestion, routing client inquiries on port `80` cleanly into Kibana pools running over port `5601`.
* **Shared Storage**: Secure, decoupled, completely private S3 storage engine dynamically provisioned with automated access blocks, targeted for data snapshots and backups.

---

## Configuration Management (`locals.tf`)

All scale bounds, pricing-tier controls, and protocol firewalls are isolated inside `locals.tf`. The node properties are grouped cleanly within respective `node_roles` schemas:

```hcl
locals {
  node_roles = {
    elasticsearch-master = {
      instance_type    = "t3.medium"
      min_size         = 3
      max_size         = 3
      desired_capacity = 3
      ingress = [ ... ]
      egress  = [ ... ]
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
* **AWS CLI**: Authenticated with appropriate permissions to provision EC2 instances, Autoscaling Groups, IAM Roles, Application Load Balancers, and S3 Buckets.
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

## Operational Guide

### How to Scale Nodes (Up or Down)
To change cluster size capacity settings (e.g., adding more data nodes to cope with storage metrics), follow these steps:
1. Open `locals.tf`.
2. Locate the specific `node_role` block (e.g., `elasticsearch-data`).
3. Modify the values for `desired_capacity` or `max_size`.
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

---

## Clean-up Playbook

When you no longer need this environment, you can remove all provisioned infrastructure. The S3 resource block contains a `force_destroy = true` argument, ensuring that all temporary cluster snapshots are purged cleanly without leaving orphan data chunks behind.

```bash
terraform destroy
```
