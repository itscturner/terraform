AWS Elastic
===========

This project provides a robust, production-grade infrastructure deployment for an Elastic cluster with Elasticsearch (Master and Data) nodes and a Kibana node on **Amazon Web Services (AWS)** running the latest **Red Hat Enterprise Linux 8 (RHEL 8)** AMI.

The system is deployed using a secure, zero-public-egress architecture. All core computation and data persistence blocks are housed exclusively within isolated private subnets across multiple dynamically discovered Availability Zones (AZs).

Storage IOPS and throughput are fine-tuned via native `gp3` parameters on the data layer, and cluster backups are managed via an encrypted Amazon S3 Snapshot repository pipeline.

---

## Architecture Overview

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                           AWS REGION (VPC)                             │
 │                                                                        │
 │   Internal VPC Clients (no Internet Gateway / no public ingress)       │
 │   │                                                                    │
 │   ├──► [ Administrative Traffic — Port 22 (SSH), VPC CIDR only ]       │
 │   │                                                                    │
 │   └──► [ Internal HTTP Clients — Port 80, VPC CIDR only ]              │
 │        │                                                               │
 │        ├──► Private Hosted Zone: api.elastic.internal                  │
 │        │    │                                                          │
 │        │    ▼                                                          │
 │        │   ┌────────────────────────────────────────────────────────┐  │
 │        │   │        Elasticsearch Ingestion Internal ALB            │  │
 │        │   └───────────────────────────┬────────────────────────────┘  │
 │        │                               │ (Forwards HTTP to Port 9200)  │
 │        │                               ▼                               │
 │        └──► Private Hosted Zone: kibana.elastic.internal               │
 │             │                                                          │
 │             ▼                                                          │
 │            ┌────────────────────────────────────────────────────────┐  │
 │            │           Kibana Frontend User Internal ALB            │  │
 │            └───────────────────────────┬────────────────────────────┘  │
 │                                        │ (Forwards HTTP to Port 5601)  │
 │                                        ▼                               │
 ├────────────────────────────────────────────────────────────────────────┤
 │              DYNAMIC MULTI-AZ PRIVATE SUBNET FLEET GRID                │
 │                                                                        │
 │   [ AVAILABILITY ZONE A ]   [ AVAILABILITY ZONE B ]   [ AZ C / ETC ]   │
 │                                                                        │
 │   ┌─────────────────────┐   ┌─────────────────────┐   ┌────────────┐   │
 │   │  ES Master Node 1   │   │  ES Master Node 2   │   │ ES Master3 │   │
 │   └─────────────────────┘   └─────────────────────┘   └────────────┘   │
 │                                                                        │
 │   ┌─────────────────────┐   ┌─────────────────────┐   ┌────────────┐   │
 │   │   ES Data Node 1    │   │   ES Data Node 2    │   │ ES Data N  │   │
 │   │  (6K IOPS / 250MBs) │   │  (6K IOPS / 250MBs) │   │ (Tuned gp3)│   │
 │   └─────────────────────┘   └─────────────────────┘   └────────────┘   │
 │                                                                        │
 │                         ┌───────────────────┐                          │
 │                         │   Kibana Server   │                          │
 │                         └───────────────────┘                          │
 │                                                                        │
 ├────────────────────────────────────────────────────────────────────────┤
 │                  SECURE DATA BACKUP STORAGE PLANE                      │
 │                                                                        │
 │   Private Node Access via IAM Instance Profile Role (No Access Keys)   │
 │   │                                                                    │
 │   ▼                                                                    │
 │  ┌──────────────────────────────────────────────────────────────────┐  │
 │  │      Encrypted S3 Snapshot Bucket (AES-256)                      │  │
 │  └──────────────────────────────────────────────────────────────────┘  │
 └────────────────────────────────────────────────────────────────────────┘
```

### Key Architectural Highlights

* **Dynamic AZ Discovery:** Eliminates hardcoded geography variables by leveraging the `aws_availability_zones` data source to automatically provision subnet boundaries across all healthy AZs in the target region.
* **Pure Boundary Isolation:** Every layer (Master, Data, and Kibana) is provisioned as its own fixed-count set of EC2 instances, sized and counted independently per role via `locals.tf`. There are no Auto Scaling Groups — instance counts are static and changed by updating the relevant `*_instance_count` variable and re-applying.
* **Internal Routing Security:** All resources live in completely private network spaces. Inbound SSH (`port 22`) and web paths are tightly locked down to internal VPC CIDR traffic.
* **Dual Internal ALBs:** Isolates data planes by routing system ingestion queries to an Elasticsearch REST API load balancer (`port 9200`) while maintaining a completely separate ALB cluster for front-end Kibana web rendering (`port 5601`).
* **Split-Horizon Private DNS:** Provisions a Route 53 Private Hosted Zone to translate long AWS balancer endpoints into human-readable corporate aliases (`api.elastic.internal` and `kibana.elastic.internal`).
* **Optimized Data Layer Storage:** The Elasticsearch data tier utilizes optimized `gp3` EBS variables running at 6,000 IOPS and 250 MB/s to completely eliminate disk indexing write bottlenecks.
* **Automated Boot Volume Mounting:** Instances execute a base64-encoded cloud-init script on boot to automatically partition secondary NVMe or standard block attachments, apply an `ext4` filesystem layout, write to `/etc/fstab`, and mount cleanly to `/mnt/elastic-data`.
* **Encrypted Snapshot Plane:** The data layer is authorized to read/write the S3 snapshot bucket via its IAM instance profile role rather than static access keys. Note: the private subnets currently have no NAT Gateway or S3 VPC Endpoint, so there is no network path to S3 yet — one of those must be added before snapshot traffic can actually reach the bucket.

---

## Project Structure

```text
aws-elastic/
├── data.tf                # Dynamic data collection (Available AZs, Latest RHEL 8 AMI)
├── locals.tf              # Node configurations grouped by role (instance counts, instance types, storage sizes)
├── main.tf                # Entrypoint organizing data lookups, network plumbing, ALBs, DNS, and S3
├── outputs.tf             # Maps endpoints, IPs, URLs, and Instance IDs
├── providers.tf           # AWS provider and Terraform block (no version constraints pinned yet)
├── variables.tf           # Global configuration variable switches
└── modules
    └── ec2/               # Module to create EC2 instances
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Configuration Management

All EC2 instance types and EC2 instance types for each node role are configured with variables and passed through `locals.tf`. The storage configurations for the EC2 instances are inside `locals.tf`.

The node properties are grouped within respective `node_roles` schemas:

```hcl
locals {
  node_roles = {
    "elasticsearch-master" = {
      instance_count = var.elasticsearch_master_instance_count
      instance_type  = var.elasticsearch_master_instance_type
      root_vol_size  = 30
      ebs_vol_size   = 50
      ebs_iops       = null # Uses AWS Default baseline (3000)
      ebs_throughput = null # Uses AWS Default baseline (125)
    }
    "elasticsearch-data" = {...}
    "kibana" = {...}
  }
}
```

---

## Step-by-Step Deployment Guide

### Prerequisites
1. **Terraform CLI Installed:** Ensure you have Terraform ready in your terminal environment.
2. **AWS CLI Installed:** Ensure the AWS CLI package is installed on your system.
3. **SSH Public Key:** A standard openSSH key string to assign to the root module.

### 1. Initialize Variables

#### Option A: Local Custom Variable File (`terraform.tfvars`)
Create a local tracking file in your root folder. **Never commit this file to git.**
```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..." # Replace with your real public key string
```
#### Option B: Update Root Variable File (`variables.tf`)
Open your root `variables.tf` file and swap out the placeholder value inside `ssh_public_key` with your live public key credentials:
```hcl
variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..." # Replace with your real public key string
}
```

### 2. Supply Your Credentials Securely
The secret access key variable is explicitly marked as `sensitive = true` to protect it from terminal exposure. Choose **one** of the following runtime methods to pass your deployment keys securely without hardcoding them into public repository code:

#### Option A: Local Custom Variable File (`terraform.tfvars`)
Create a local tracking file in your root folder. **Never commit this file to git.**
```hcl
aws_access_key = "AKIAIOSFODNN7EXAMPLE"
aws_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

#### Option B: Environment Variables Injection
Prefix your tokens with `TF_VAR_` inside your target deployment container or bash shell:
```bash
export TF_VAR_aws_access_key="AKIAIOSFODNN7EXAMPLE"
export TF_VAR_aws_secret_key="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

### 3. Initialize Working Directory
Downloads external lock dependencies, prepares system directories, and initiates the core module links.
```bash
terraform init
```

### 4. Verify State and Resource Execution Maps
Performs a semantic compilation check. This outputs exactly what infrastructure will be created, modified, or safely recycled without causing drift.
```bash
terraform plan
```

### 5. Build Cluster Resources
Deploys the infrastructure to your AWS account. Review the generation blueprint and type `yes` when prompted.
```bash
terraform apply
```

---

## Accessing the Kibana Frontend Interface
Once Terraform finishes successfully, the CLI will return a series of configuration variables. Use the provided entry point to load the Kibana platform:

```bash
terraform output kibana_endpoint
```

---

## Clean-up Guide

When you no longer need this environment, you can remove all provisioned infrastructure using the following command:

```bash
terraform destroy
```

---

## 🛡️ Security Port Control Reference Matrix

| Port Boundary     | Protocol | Traffic Scope Source            | Intent and Operations                                           |
| :---              | :---     | :---                            | :---                                                            |
| **TCP / `22`**    | SSH      | `var.vpc_cidr` (VPC Space Only) | Secure terminal management access                               |
| **HTTPS / `443`** | TLS      | `elastic-ec2-iam-role`          | IAM-authorized outbound requests to the S3 Snapshots Bucket (needs a NAT Gateway or S3 VPC Endpoint — not yet provisioned) |
| **TCP / `5601`**  | HTTP     | `elastic-kibana-alb-sg`         | Restricts Kibana backend access purely to requests from its ALB |
| **TCP / `9200`**  | HTTP     | `self` / `elastic-es-alb-sg`    | Ingestion API pipeline query engine access                      |
| **TCP / `9300`**  | TCP      | `self` (Within `elastic_sg`)    | Isolated Elasticsearch Inter-node Shard Cluster Routing         |
