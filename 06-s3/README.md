# Phase 6 — S3

## Objective

This phase keeps the focus on **one S3 bucket** and uses it to demonstrate how Terraform configuration is structured: arguments, maps, variables, and nested configuration blocks.

## Directory Structure

```text
06-s3/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

| File           | Role                                        |
| -------------- | ------------------------------------------- |
| `versions.tf`  | Declares the required provider              |
| `variables.tf` | Inputs: `bucket_name` and `environment`     |
| `main.tf`      | The S3 bucket resource                      |
| `outputs.tf`   | Exposes the bucket name and ARN             |

```text
variables.tf ──► main.tf ──► outputs.tf
 (inputs)       (S3 bucket)   (results)
```

---

## `versions.tf`

Declares which provider Terraform needs and where to download it from.

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

`source = "hashicorp/aws"` tells `terraform init` to download the AWS provider from the Terraform Registry.

---

## `variables.tf`

Defines the inputs for this phase.

```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}
```

| Variable      | Type     | Default | Notes                                   |
| ------------- | -------- | ------- | --------------------------------------- |
| `bucket_name` | `string` | none    | **Required.** You must supply a value   |
| `environment` | `string` | `"lab"` | Optional. Used for tagging              |

S3 bucket names are **globally unique** across all AWS accounts, so `bucket_name` has no default. Choose a unique name when you run the lab, for example in `terraform.tfvars`:

```hcl
bucket_name = "my-unique-terraform-lab-bucket-12345"
```

---

## `main.tf`

Contains the single S3 bucket resource.

```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

Breaking it down:

```text
aws_s3_bucket
      │
      └── Resource type

my_bucket
      │
      └── Local Terraform name

aws_s3_bucket.my_bucket
      │
      └── How other blocks reference it
```

| Part                                 | Meaning                                              |
| ------------------------------------ | ---------------------------------------------------- |
| `bucket = var.bucket_name`           | The bucket name comes from a variable                |
| `tags = { ... }`                     | A map of key/value tags attached to the bucket       |
| `Name = var.bucket_name`             | Tag value taken from a variable                      |
| `Environment = var.environment`      | Tag value taken from a variable                      |
| `ManagedBy = "Terraform"`            | A fixed tag showing how the bucket is managed        |

---

## `outputs.tf`

Exposes useful values after `terraform apply`.

```hcl
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.arn
}
```

The references follow the pattern `<resource_type>.<local_name>.<attribute>`:

```text
aws_s3_bucket.my_bucket.bucket   → the bucket name
aws_s3_bucket.my_bucket.arn      → the bucket ARN
```

After `terraform apply`, Terraform displays:

```text
Outputs:

bucket_arn  = "arn:aws:s3:::my-unique-terraform-lab-bucket-12345"
bucket_name = "my-unique-terraform-lab-bucket-12345"
```

---

## Terraform Commands

Initialize:

```bash
terraform init
```

Format and validate:

```bash
terraform fmt
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

Show outputs:

```bash
terraform output
```

Verify the bucket with the AWS CLI:

```bash
aws s3 ls
```

Cleanup:

```bash
terraform destroy
```

---

## Key Takeaways

- This phase focuses on a single S3 bucket
- `versions.tf` declares the provider, `variables.tf` defines inputs, `main.tf` creates the bucket, and `outputs.tf` exposes results
- S3 bucket names are globally unique, so `bucket_name` is a required variable with no default
- `tags` is a map argument written with `=`; nested blocks are written without `=`
- Outputs reference the resource as `aws_s3_bucket.my_bucket.<attribute>`