# Phase 5 — IAM

This directory demonstrates how Terraform can be used to manage AWS Identity and Access Management (IAM) resources.

The primary goal is to understand how **IAM roles, policies, and service identities** work together.

## Architecture

```text
                         Terraform
                             │
                             ▼
                           IAM
                             │
                             ▼
                         IAM Role
                             │
                             ▼
                        IAM Policy
                             │
                             ▼
                    S3 Read-Only Access
```

The main AWS pattern demonstrated here is:

```text
EC2
 │
 └── IAM Role
       │
       └── IAM Policy
              │
              └── S3 Read-Only Permissions
```

This is a common AWS pattern for granting permissions to workloads without storing long-lived AWS access keys on the workload.

---

## What This Phase Demonstrates

- IAM Role
- IAM Policy
- IAM Role Policy Attachment
- EC2 Instance Profile
- IAM trust policy
- IAM permissions policy
- Authentication vs authorization
- User vs Role vs Policy
- Service-to-role access

---

# Authentication vs Authorization

These two concepts should not be confused.

## Authentication

Authentication answers:

> **Who are you?**

Examples:

```text
AWS user authenticates with credentials
EC2 identifies itself through an IAM role
Application obtains temporary credentials through a role
```

Authentication establishes an identity.

---

## Authorization

Authorization answers:

> **What are you allowed to do?**

IAM policies define permissions.

For example:

```text
Allow:
    s3:GetObject
    s3:ListBucket
```

The policy determines what actions the identity can perform.

Therefore:

```text
Authentication
      ↓
Who are you?
      ↓
Authorization
      ↓
What can you do?
```

---

# IAM User vs Role vs Policy

## IAM User

An IAM user represents a persistent AWS identity.

Typical example:

```text
Human administrator
        │
        ▼
    IAM User
```

A user can have credentials and permissions associated with it.

However, IAM users should not be created unnecessarily for workloads.

For example, an EC2 instance should generally not use an IAM user's access key.

---

## IAM Role

A role is an identity that can be **assumed** by a trusted principal.

For example:

```text
EC2
 │
 │ AssumeRole
 ▼
IAM Role
```

The role provides temporary credentials to the workload.

This avoids embedding long-lived AWS access keys into applications or servers.

---

## IAM Policy

A policy defines permissions.

Example:

```text
Allow
    s3:GetObject
    s3:ListBucket
```

A policy does not represent an identity.

Instead:

```text
Identity
   │
   └── Role
        │
        └── Policy
             │
             └── Permissions
```

---

# Trust Policy vs Permissions Policy

This is one of the most important IAM concepts in this example.

The role contains a **trust policy**:

```hcl
assume_role_policy = jsonencode({
  Version = "2012-10-17"

  Statement = [
    {
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }
  ]
})
```

This answers:

> Who can assume this role?

The answer is:

```text
EC2
```

---

The separate IAM policy defines permissions:

```text
s3:GetObject
s3:ListBucket
```

This answers:

> What can the role do?

Therefore:

```text
Trust Policy
    ↓
Who can assume the role?

Permissions Policy
    ↓
What can the role do?
```

These are separate concepts.

---

# EC2 Role Architecture

The intended architecture is:

```text
                    AWS
                     │
                     ▼
                    EC2
                     │
                     │ instance profile
                     ▼
              IAM Instance Profile
                     │
                     ▼
                 IAM Role
                     │
                     │ attached policy
                     ▼
                IAM Policy
                     │
                     ▼
             S3 Read Permissions
```

Terraform creates the instance profile:

```hcl
resource "aws_iam_instance_profile" "ec2_s3_readonly" {
  name = "terraform-lab-ec2-s3-readonly"
  role = aws_iam_role.ec2_s3_readonly.name
}
```

The instance profile is the mechanism used to associate the IAM role with an EC2 instance.

When an EC2 instance is eventually created, it can reference:

```hcl
iam_instance_profile = aws_iam_instance_profile.ec2_s3_readonly.name
```

The EC2 instance can then obtain temporary credentials through the role.

---

# Why Use a Role Instead of Access Keys?

Avoid this pattern:

```text
EC2
 │
 ├── AWS_ACCESS_KEY_ID
 └── AWS_SECRET_ACCESS_KEY
```

Long-lived credentials create unnecessary credential-management problems.

Prefer:

```text
EC2
 │
 ▼
IAM Role
 │
 ▼
Temporary Credentials
 │
 ▼
AWS API
```

The workload receives credentials associated with the role instead of requiring manually managed IAM user credentials.

---

# Terraform Resources

## `aws_iam_role`

Creates the IAM role.

```hcl
resource "aws_iam_role" "ec2_s3_readonly" {
  name = "terraform-lab-ec2-s3-readonly"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}
```

The `assume_role_policy` defines the role's trust relationship: only the EC2 service (`ec2.amazonaws.com`) is allowed to assume this role.

---

## `aws_iam_policy`

Creates a reusable IAM permissions policy.

```hcl
resource "aws_iam_policy" "s3_readonly" {
  name        = "terraform-lab-s3-readonly"
  description = "Allows read-only access to S3"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]

        Resource = "*"
      }
    ]
  })
}
```

This policy allows two actions:

| Action          | Purpose                          |
| --------------- | -------------------------------- |
| `s3:GetObject`  | Read objects from a bucket       |
| `s3:ListBucket` | List the objects inside a bucket |

`Resource = "*"` applies the permissions to **all** S3 buckets and objects in the account. This is convenient for a lab, but in a real environment the resource should be restricted to specific bucket ARNs (following least privilege).

---

## `aws_iam_role_policy_attachment`

Attaches the permissions policy to the role.

```hcl
resource "aws_iam_role_policy_attachment" "ec2_s3_readonly" {
  role       = aws_iam_role.ec2_s3_readonly.name
  policy_arn = aws_iam_policy.s3_readonly.arn
}
```

The result is:

```text
Role
 │
 └── S3 ReadOnly Policy
```

---

## `aws_iam_instance_profile`

Creates the EC2 instance profile associated with the role.

```hcl
resource "aws_iam_instance_profile" "ec2_s3_readonly" {
  name = "terraform-lab-ec2-s3-readonly"
  role = aws_iam_role.ec2_s3_readonly.name
}
```

---

# Resource Relationship

Terraform builds the dependency graph from the references in `main.tf`:

```text
aws_iam_role.ec2_s3_readonly            aws_iam_policy.s3_readonly
        │              │                          │
        │              └───────────┐   ┌──────────┘
        ▼                          ▼   ▼
aws_iam_instance_profile      aws_iam_role_policy_attachment
.ec2_s3_readonly              .ec2_s3_readonly
```

- `aws_iam_instance_profile` references the role's `name`
- `aws_iam_role_policy_attachment` references the role's `name` and the policy's `arn`
- The role and the policy have no dependency on each other, so Terraform can create them in parallel

The role also has a trust relationship:

```text
EC2 Service
     │
     │ sts:AssumeRole
     ▼
IAM Role
```

---

# Deploy

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt
```

Validate:

```bash
terraform validate
```

Review the plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

---

# Verify

Check the Terraform outputs:

```bash
terraform output
```

Check the role:

```bash
aws iam get-role \
  --role-name terraform-lab-ec2-s3-readonly
```

Check the policy:

```bash
aws iam get-policy \
  --policy-arn "$(terraform output -raw iam_policy_arn)"
```

Check the policy attachment:

```bash
aws iam list-attached-role-policies \
  --role-name terraform-lab-ec2-s3-readonly
```

Check the instance profile:

```bash
aws iam get-instance-profile \
  --instance-profile-name terraform-lab-ec2-s3-readonly
```

---

# Cleanup

Destroy the resources when finished:

```bash
terraform destroy
```

IAM resources created in this lab should not be left behind unnecessarily.

---

# Key Takeaways

The most important concept from this phase is the separation between **identity, trust, and permissions**.

```text
IAM Role
   │
   ├── Trust Policy
   │      └── Who can assume me?
   │
   └── Permissions Policy
          └── What can I do?
```

For AWS workloads, prefer:

```text
AWS Service
     ↓
IAM Role
     ↓
IAM Policy
     ↓
AWS Resources
```

over distributing long-lived IAM user credentials to applications or servers.