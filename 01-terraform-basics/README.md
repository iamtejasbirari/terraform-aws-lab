# Terraform Basics

A learning module covering the fundamentals of Terraform using a simple AWS S3 bucket.

## Table of Contents

- [What is Terraform?](#what-is-terraform)
- [What is a Terraform Provider?](#what-is-a-terraform-provider)
- [What is a Resource?](#what-is-a-resource)
- [Terraform Configuration](#terraform-configuration)
- [Terraform Workflow](#terraform-workflow)
- [What is Terraform State?](#what-is-terraform-state)
- [Terraform Dependency Graph](#terraform-dependency-graph)
- [Desired State vs Actual State](#desired-state-vs-actual-state)
- [Terraform Commands Learned](#terraform-commands-learned)
- [Recommended Workflow](#recommended-workflow)
- [Complete Lifecycle](#complete-lifecycle)
- [Key Concepts](#key-concepts)

---

## What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool developed by HashiCorp.

It allows infrastructure to be defined using configuration files instead of manually creating resources through a cloud provider's console.

For example:

```hcl
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
}
```

Terraform reads this configuration and determines what needs to exist in AWS.

Terraform can then:

- Create infrastructure
- Modify infrastructure
- Delete infrastructure
- Track infrastructure
- Calculate infrastructure changes before applying them

The basic workflow is:

```text
Write configuration
       │
       ▼
terraform init
       │
       ▼
terraform plan
       │
       ▼
terraform apply
       │
       ▼
Infrastructure
```

---

## What is a Terraform Provider?

Terraform itself does not know how to communicate with AWS, Azure, Kubernetes, GitHub, etc.

Terraform uses **providers** to communicate with external APIs.

Examples:

```text
Terraform
   │
   ├── AWS Provider
   │      └── AWS API
   │
   ├── Kubernetes Provider
   │      └── Kubernetes API
   │
   └── GitHub Provider
          └── GitHub API
```

For this project we use the AWS provider:

```hcl
provider "aws" {
  region = var.aws_region
}
```

The provider knows how to communicate with AWS APIs and manage AWS resources.

The provider is declared in:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}
```

---

## What is a Resource?

A Terraform resource represents infrastructure that Terraform manages.

Example:

```hcl
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
}
```

Here:

```text
aws_s3_bucket
      │
      └── Resource type

s3_bucket
      │
      └── Local Terraform name
```

Terraform resource references use:

```text
aws_s3_bucket.s3_bucket
```

For example:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.s3_bucket.bucket
}
```

A resource can represent many different types of infrastructure:

```text
AWS
├── aws_s3_bucket
├── aws_instance
├── aws_vpc
├── aws_subnet
├── aws_security_group
└── aws_iam_role
```

The resource type determines what Terraform knows how to create and manage.

---

## Terraform Configuration

This module contains four Terraform configuration files:

```text
provider.tf
variables.tf
main.tf
outputs.tf
```

Terraform automatically loads all `.tf` files in the directory.

The files are separated for organization. They could technically be placed into one file, but separating configuration makes larger Terraform projects easier to understand and maintain.

### provider.tf

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

This defines:

1. Terraform version requirement
2. Required providers
3. AWS provider configuration

### variables.tf

Variables allow configuration values to be supplied without hardcoding them directly into resources.

Example:

```hcl
variable "aws_region" {
  description = AWS region where Terraform resource will be created"
  type        = string
  default     = "ap-south-1"
}
```

The variable can then be referenced as:

```text
var.aws_region
```

This creates a separation between:

```text
Configuration
      │
      ▼
Variables
      │
      ▼
Resources
```

### main.tf

`main.tf` contains the infrastructure resources.

Example:

```hcl
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    ManagedBy   = "Terraform"
  }
}
```

Terraform will compare the desired configuration with the current state and determine whether the bucket needs to be created, changed, or destroyed.

### outputs.tf

Outputs expose useful values after Terraform creates infrastructure.

Example:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.s3_bucket.bucket
}
```

After:

```bash
terraform apply
```

Terraform displays:

```text
Outputs:

bucket_name = "..."
bucket_arn  = "..."
```

Outputs are also useful when one Terraform resource or module needs to expose information to another.

---

## Terraform Workflow

### 1. terraform init

Run:

```bash
terraform init
```

Terraform initializes the working directory. It will:

- Download the required providers
- Initialize the Terraform working directory
- Create `.terraform/`
- Create/update `.terraform.lock.hcl`

Example:

```text
terraform init
        │
        ├── Read required providers
        │
        ├── Download AWS provider
        │
        └── Initialize working directory
```

After initialization, you will typically see:

```text
.terraform/
.terraform.lock.hcl
```

#### What is `.terraform/`?

`.terraform/` is a Terraform working directory created by Terraform. It contains local Terraform working data, including downloaded provider plugins.

Example:

```text
.terraform/
└── providers/
    └── registry.terraform.io/
        └── hashicorp/
            └── aws/
```

This directory should normally **not** be committed to Git. Add it to `.gitignore`:

```text
.terraform/
```

#### What is `.terraform.lock.hcl`?

This file records the selected provider version and checksums.

Unlike `.terraform/`, this file should normally be **committed** to Git. It helps ensure that different environments use the same verified provider package.

### 2. terraform plan

Run:

```bash
terraform plan
```

Terraform creates an execution plan. The plan answers:

> What will Terraform change if I apply this configuration?

For a new S3 bucket you should see something similar to:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Terraform has not created anything yet. The important concept is:

```text
terraform plan
       │
       ▼
Calculate changes
       │
       ▼
Show proposed changes
       │
       ▼
No infrastructure change
```

### 3. terraform apply

Run:

```bash
terraform apply
```

Terraform will calculate the plan and ask for confirmation. Enter:

```text
yes
```

Terraform then creates the S3 bucket. You should see:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

The workflow becomes:

```text
terraform apply
       │
       ▼
Read configuration
       │
       ▼
Read Terraform state
       │
       ▼
Compare desired vs current
       │
       ▼
Build dependency graph
       │
       ▼
Call AWS API
       │
       ▼
Create S3 bucket
       │
       ▼
Update Terraform state
```

### 4. terraform destroy

Run:

```bash
terraform destroy
```

Terraform determines which infrastructure it manages and removes it. You will be asked for confirmation. Enter:

```text
yes
```

Expected result:

```text
Destroy complete! Resources: 1 destroyed.
```

The lifecycle is therefore:

```text
terraform apply
      │
      ▼
Create infrastructure
      │
      ▼
Manage infrastructure
      │
      ▼
terraform destroy
      │
      ▼
Remove infrastructure
```

---

## What is Terraform State?

Terraform needs to know what infrastructure it manages. Terraform stores this information in a state file:

```text
terraform.tfstate
```

The state connects Terraform configuration with real infrastructure. Conceptually:

```text
Terraform Configuration
        │
        │ Desired state
        ▼
Terraform
        │
        │ Compare
        ▼
terraform.tfstate
        │
        │ Known infrastructure
        ▼
AWS
        │
        │ Actual infrastructure
        ▼
S3 Bucket
```

For example, Terraform configuration may contain:

```hcl
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
}
```

The state records information about the actual bucket Terraform created. Terraform uses this information during future plans and applies.

State files can contain sensitive infrastructure information.

In production environments, Terraform state is normally stored remotely using a backend with appropriate access control and locking. Remote state will be covered later in this repository.

---

## Terraform Dependency Graph

Terraform builds a dependency graph to determine the order in which resources should be created, changed, or destroyed.

For example:

```text
VPC
 │
 ├── Subnet
 │     │
 │     └── EC2 Instance
 │
 └── Security Group
       │
       └── EC2 Instance
```

Terraform understands these dependencies from resource references.

Example:

```hcl
resource "aws_instance" "app" {
  subnet_id = aws_subnet.app.id
}
```

Because `aws_instance.app` references `aws_subnet.app.id`, Terraform knows that the subnet must exist before the instance can be created.

Terraform can visualize the dependency graph using:

```bash
terraform graph
```

For a more readable graph, the output can be passed to Graphviz:

```bash
terraform graph | dot -Tpng > graph.png
```

---

## Desired State vs Actual State

One of Terraform's core concepts is **desired state**.

The Terraform configuration describes what we want:

```text
Desired State
     │
     ▼
Terraform Configuration
```

AWS contains the actual infrastructure:

```text
Actual State
     │
     ▼
AWS
```

Terraform compares these and determines what actions are required.

```text
             Terraform
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
 Desired State       Known State
   *.tf files       terraform.tfstate
        │                 │
        └────────┬────────┘
                 ▼
          Calculate Diff
                 │
                 ▼
              Plan
                 │
                 ▼
              Apply
```

---

## Terraform Commands Learned

| Command              | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `terraform init`     | Initialize Terraform and download providers  |
| `terraform fmt`      | Format Terraform configuration               |
| `terraform validate` | Validate Terraform configuration             |
| `terraform plan`     | Preview infrastructure changes               |
| `terraform apply`    | Create/update infrastructure                 |
| `terraform destroy`  | Destroy managed infrastructure               |
| `terraform show`     | Display Terraform state/plan information     |
| `terraform output`   | Display Terraform outputs                    |
| `terraform graph`    | Display Terraform dependency graph           |

---

## Recommended Workflow

For this repository, use:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

After making changes:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

When finished learning:

```bash
terraform destroy
```

---

## Complete Lifecycle

The complete Terraform lifecycle learned in this module is:

```text
                 Terraform
                     │
                     ▼
              Configuration
                 *.tf files
                     │
                     ▼
              terraform init
                     │
                     ▼
             Provider installed
                     │
                     ▼
              terraform plan
                     │
                     ▼
             Review changes
                     │
                     ▼
             terraform apply
                     │
                     ▼
              AWS Resource
                     │
                     ▼
             Terraform State
                     │
                     ▼
            Change configuration
                     │
                     ▼
              terraform plan
                     │
                     ▼
             terraform apply
                     │
                     ▼
             Updated Resource
                     │
                     ▼
             terraform destroy
                     │
                     ▼
             Resource Removed
```

---

## Key Concepts

After completing this module, you should understand:

- What Terraform is
- What Infrastructure as Code means
- What a Terraform provider is
- What a Terraform resource is
- What variables are
- What outputs are
- What `terraform init` does
- What `terraform plan` does
- What `terraform apply` does
- What `terraform destroy` does
- What `.terraform/` contains
- What `.terraform.lock.hcl` does
- What Terraform state is
- Why `terraform.tfstate` should not be committed
- How Terraform determines dependencies
- What Terraform's dependency graph represents
- The difference between desired state and actual infrastructure