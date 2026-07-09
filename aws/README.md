AWS
===

This Terraform project automates the deployment of a scalable infrastructure on Amazon Web Services (AWS). It leverages Infrastructure as Code (IaC) to provision a dynamic pool of Amazon Elastic Compute Cloud (EC2) instances integrated with a centralized Amazon Simple Storage Service (S3) bucket for unified data storage.

Architecture
---

```
                   Internet
                       │
                Internet Gateway
                       │
                 Public Subnet
                       │
     ┌────────────┬────────────┬────────────┐
     │            │            │
   EC2 #1      EC2 #2      EC2 #3 ... EC2 #N
     │            │            │
     └────────────┴────────────┘
                 Security Group
    (All instances can communicate internally)
                       │
             IAM Instance Profile
                       │
               Shared S3 Bucket
```

Project Structure
---

```
aws/
├── modules/
│   ├── ec2/               # EC2 Module
|     └── main.tf
|     └── outputs.tf
|     └── variables.tf
│   ├── iam/               # IAM Module
|     └── main.tf
|     └── outputs.tf
|     └── variables.tf
│   ├── s3/                # S3 Module
|     └── main.tf
|     └── outputs.tf
|     └── variables.tf
│   └── security/          # Security Module
|     └── main.tf
|     └── outputs.tf
|     └── variables.tf
│   ├── vpc/               # VPC Module
|     └── main.tf
|     └── outputs.tf
|     └── variables.tf
│── main.tf                # Main Terraform Configuration File
│── outputs.tf             # Output Values
│── providers.tf           # Providers File
│── terraform.tfvars       # TFVars File
│── variables.tf           # Variables for Terraform
│── README.md              # Documentation
```

Prerequisites
---

Before deploying this project, ensure you have the following installed:

#### **Install Terraform**
- Download Terraform from the official site: [Terraform Download](https://www.terraform.io/downloads)
- Install it by following the instructions for your OS.
- Verify installation by running:
  ```sh
  terraform -version
  ```

#### **Configure AWS CLI**
- Install AWS CLI: [AWS CLI Installation](https://aws.amazon.com/cli/)
- Configure it with your AWS credentials:
  ```sh
  aws configure
  ```

Deployment Guide
---

**Initialize Terraform**
```
terraform init
```

**Plan Deployment**
```
terraform plan
```

**Apply Configuration**
```
terraform apply -auto-approve
```

Outputs
---

**Instance IDs**
```
instances = module.ec2.instance_ids
```

**S3 Bucket Name**
```
bucket = module.s3.bucket_name
```
