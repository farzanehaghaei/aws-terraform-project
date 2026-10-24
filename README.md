# AWS Secure Infrastructure — Terraform

> Secure, multi-environment AWS infrastructure built with Terraform and deployed via GitHub Actions CI/CD — following DevSecOps best practices.

[![Terraform](https://img.shields.io/badge/Terraform-1.7-purple?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)](https://aws.amazon.com)
[![CI/CD](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-blue?logo=github-actions)](https://github.com/features/actions)
[![Security](https://img.shields.io/badge/tfsec-scanning-green)](https://github.com/aquasecurity/tfsec)

---

## What this project does

This project provisions a **secure, production-ready AWS environment** using reusable Terraform modules.
It is designed for teams that need consistent, auditable infrastructure across multiple environments (dev and prod).

Everything is automated:
- Infrastructure is defined as code — no manual clicks in the AWS console
- Every pull request triggers a `terraform plan` so the team sees changes before they are applied
- Every merge to `main` triggers `terraform apply` automatically
- Security scanning runs on every pull request with **tfsec**

---

## Infrastructure overview

```
Internet
    │
    ▼
┌─────────────────────────────────────┐
│  VPC  (10.0.0.0/16)                │
│                                     │
│  ┌──────────────┐                  │
│  │ Public Subnet│  (load balancer) │
│  └──────────────┘                  │
│                                     │
│  ┌──────────────┐                  │
│  │Private Subnet│ ← EC2 lives here │
│  │  [EC2]       │   no public IP   │
│  └──────┬───────┘                  │
│         │ IAM role (least priv.)   │
│         ▼                          │
│  ┌──────────────┐                  │
│  │  S3 Bucket   │  encrypted +     │
│  │              │  versioned       │
│  └──────────────┘                  │
└─────────────────────────────────────┘
```

---

## What this builds

| Resource | Configuration |
|---|---|
| **VPC** | 10.0.0.0/16 — 2 public + 2 private subnets across 2 AZs |
| **EC2** | t3.micro, private subnet, encrypted disk, IMDSv2 enforced |
| **S3** | AES-256 encryption, versioning, public access blocked, access logs |
| **Security Group** | Least-privilege — only HTTPS from inside VPC |
| **IAM Role** | EC2 can only read/write its own S3 bucket — nothing else |

---

## Security features

| Feature | Why it matters |
|---|---|
| EC2 in **private subnet** | No direct internet access — attackers cannot reach it |
| **No SSH key** on EC2 | Use SSM Session Manager instead — no open port 22 |
| **IMDSv2 enforced** | Blocks SSRF attacks that steal instance credentials |
| S3 **public access blocked** | Data cannot be exposed by misconfiguration |
| **AES-256 encryption** at rest | Data is protected even if storage media is stolen |
| S3 **versioning** enabled | Accidental deletions or ransomware can be recovered |
| **Least-privilege IAM** | EC2 can only access its own bucket — blast radius is small |
| **tfsec** in CI/CD | Security issues are caught before infrastructure is created |

---

## Project structure

```
aws-terraform-project/
├── .github/
│   └── workflows/
│       └── terraform.yml      # CI/CD: plan on PR, apply on merge
│
├── modules/                   # Reusable building blocks
│   ├── networking/
│   │   ├── main.tf            # VPC, subnets, internet gateway, route tables
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf            # EC2, security group, IAM role + policy
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/
│       ├── main.tf            # S3 bucket, encryption, versioning, logging
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev/                   # Development — t3.micro, 20GB disk
│   │   ├── main.tf            # calls all 3 modules
│   │   ├── provider.tf        # AWS provider + remote state config
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── example.tfvars     # copy to terraform.tfvars to run
│   └── prod/                  # Production — t3.small, 50GB disk
│       ├── main.tf
│       ├── provider.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── .gitignore                 # excludes *.tfstate, *.tfvars, .terraform/
└── README.md
```

---

## How to use

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- AWS CLI configured: `aws configure`
- An AWS account with permissions to create VPC, EC2, S3, IAM

### Deploy dev environment

```bash
# 1. Clone the repo
git clone https://github.com/farzanehaghaei/aws-terraform-project.git
cd aws-terraform-project

# 2. Go to the dev environment
cd environments/dev

# 3. Copy the example variables file
cp example.tfvars terraform.tfvars

# 4. Initialize Terraform (downloads AWS provider)
terraform init

# 5. Preview what will be created (no changes yet)
terraform plan

# 6. Create the infrastructure
terraform apply

# 7. Clean up when done (avoids AWS costs)
terraform destroy
```

### Deploy prod environment

```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

---

## CI/CD pipeline

```
Pull Request opened
        │
        ▼
  terraform fmt     ← fails if code is not formatted
        │
        ▼
  terraform validate ← fails if syntax is wrong
        │
        ▼
  tfsec scan        ← warns about security issues
        │
        ▼
  terraform plan    ← posts plan as PR comment
        │
   (PR merged)
        │
        ▼
  terraform apply   ← creates real infrastructure
```

**GitHub Secrets required** (Settings → Secrets → Actions):
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## Key design decisions

**Why private subnet for EC2?**
EC2 instances with public IPs are a common attack surface. By placing the instance in a private subnet with no public IP, the only way to access it is through SSM Session Manager — which requires valid AWS credentials.

**Why no SSH key?**
SSH keys can be lost, stolen, or shared. SSM Session Manager provides auditable, credential-based access with full session logging — no open port 22 required.

**Why reusable modules?**
The same networking, compute, and storage modules are used in both dev and prod. Changes to a module automatically apply to all environments — no copy-paste drift.

**Why separate state per environment?**
A failed prod apply does not affect dev state. Teams can work on dev and prod independently without state conflicts.

---

## Author

**Farzaneh Aghaei** — Cloud & DevSecOps Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Farzaneh_Aghaei-blue?logo=linkedin)](https://linkedin.com/in/farzanehaghaei)
[![GitHub](https://img.shields.io/badge/GitHub-farzanehaghaei-black?logo=github)](https://github.com/farzanehaghaei)
