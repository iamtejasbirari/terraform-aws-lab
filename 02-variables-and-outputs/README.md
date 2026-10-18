# Phase 2 - Terraform Variables, Validation and Outputs

This phase replaces hardcoded values with variables, adds validation, and exposes results through outputs, using an AWS EC2 instance as the example.

## Table of Contents

1. [Hardcoded Values](#1-hardcoded-values)
2. [Using Variables](#2-using-variables)
3. [Why Use Variables?](#3-why-use-variables)
4. [Variable Types](#4-variable-types)
5. [Default Values](#5-default-values)
6. [terraform.tfvars](#6-terraformtfvars)
7. [Variable Validation](#7-variable-validation)
8. [Outputs](#8-outputs)
9. [Complete Terraform Flow](#9-complete-terraform-flow)
10. [Initialize Terraform](#10-initialize-terraform)
11. [Format the Configuration](#11-format-the-configuration)
12. [Validate Configuration](#12-validate-configuration)
13. [Create terraform.tfvars](#13-create-terraformtfvars)
14. [Review the Plan](#14-review-the-plan)
15. [Apply](#15-apply)
16. [View Outputs](#16-view-outputs)
17. [Test Variable Validation](#17-test-variable-validation)
18. [Important Concepts](#18-important-concepts)
19. [Cleanup](#19-cleanup)

---

## 1. Hardcoded Values

A basic Terraform resource can contain hardcoded configuration:

```hcl
resource "aws_instance" "my_instance" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"
}
```

This works, but the configuration is tightly coupled to the resource. If we want to change the instance type, we have to modify the Terraform code.

---

## 2. Using Variables

Instead, define the value as a variable:

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

Then reference it from the resource:

```hcl
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

The flow becomes:

```text
Configuration value
        ↓
    variable
        ↓
     resource
        ↓
      output
```

---

## 3. Why Use Variables?

**Hardcoded**

```hcl
instance_type = "t3.micro"
```

The value is directly embedded inside the resource.

**Variable**

```hcl
instance_type = var.instance_type
```

The resource gets the value from a variable. The variable can then be changed without modifying the resource itself.

For example:

```hcl
instance_type = "t3.micro"
```

can become:

```hcl
instance_type = "t2.micro"
```

through `terraform.tfvars`.

This separates:

```text
Infrastructure definition
```

from:

```text
Configuration values
```

---

## 4. Variable Types

Terraform allows variables to have explicit types.

Example:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}
```

Here:

```text
variable       → variable name
description    → documentation
type           → expected data type
default        → default value
```

Common Terraform types include:

```text
string
number
bool
list
set
map
object
tuple
```

At this stage we use `string` because the values being passed are strings.

---

## 5. Default Values

A variable can have a default value:

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

If no value is supplied, Terraform uses:

```text
t3.micro
```

For example, if `terraform.tfvars` does not contain `instance_type`, Terraform uses the default.

---

## 6. terraform.tfvars

Terraform automatically loads values from:

```text
terraform.tfvars
```

Example:

```hcl
aws_region = "ap-south-1"

ami_id = "ami-xxxxxxxx"

instance_type = "t3.micro"

environment = "dev"
```

Terraform maps these values to the variables defined in `variables.tf`. The relationship is:

```text
terraform.tfvars
       ↓
variables.tf
       ↓
     var.*
       ↓
   resource
```

---

## 7. Variable Validation

Terraform can validate variable values before creating infrastructure.

Example:

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains(
        ["dev", "stage", "prod"],
        var.environment
    )

    error_message = "environment must be dev, stage or prod"
  }
}
```

Valid:

```hcl
instance_type = "dev"
```

Valid:

```hcl
instance_type = "stage"
```

Valid:

```hcl
instance_type = "prod"
```

Invalid:

```hcl
instance_type = "sandbox"
```

Terraform stops before provisioning the resource. This is useful for preventing invalid configuration from reaching infrastructure.

---

## 8. Outputs

Outputs expose useful information after Terraform creates resources.

Example:

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.example.id
}
```

Another example:

```hcl
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.example.public_ip
}
```

After:

```bash
terraform apply
```

Terraform displays:

```text
Outputs:

environment = "dev"
instance_id = "i-xxxxxxxxxxxxxxxxx"
instance_type = "t3.micro"
```

---

## 9. Complete Terraform Flow

The complete flow in this phase is:

```text
terraform.tfvars
       │
       │
       ▼
   variables.tf
       │
       │ var.instance_type
       ▼
     main.tf
       │
       │
       ▼
 AWS EC2 Instance
       │
       │
       ▼
   outputs.tf
       │
       ▼
 Terraform Output
```

---

## 10. Initialize Terraform

From this directory:

```bash
terraform init
```

---

## 11. Format the Configuration

```bash
terraform fmt
```

Check formatting:

```bash
terraform fmt -check
```

---

## 12. Validate Configuration

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

## 13. Create terraform.tfvars

Copy the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit the file:

```bash
vim terraform.tfvars
```

Set a valid AMI ID:

```hcl
aws_region    = "ap-south-1"
ami_id        = "YOUR_AMI_ID"
instance_type = "t3.micro"
environment   = "dev"
```

---

## 14. Review the Plan

```bash
terraform plan
```

Terraform evaluates the variables and shows what it intends to create.

---

## 15. Apply

```bash
terraform apply
```

Review the plan and enter:

```text
yes
```

---

## 16. View Outputs

```bash
terraform output
```

Individual outputs can also be queried:

```bash
terraform output instance_id
```

---

## 17. Test Variable Validation

Change:

```hcl
instance_type = "sandbox"
```

Run:

```bash
terraform plan
```

Terraform should reject the value with:

```text
instance_type must be either dev, stage or prod.
```

Change it back:

```hcl
instance_type = "dev"
```

---

## 18. Important Concepts

### Variable

Defines an input to Terraform:

```hcl
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
```

### `var.<name>`

References a variable:

```hcl
instance_type = var.instance_type
```

### `terraform.tfvars`

Provides values for variables:

```hcl
instance_type = "t3.micro"
```

### Default

Provides a fallback value:

```hcl
default = "t3.micro"
```

### Type

Defines the expected data type:

```hcl
type = string
```

### Description

Documents what the variable represents:

```hcl
description = "EC2 instance type"
```

### Validation

Restricts acceptable values:

```hcl
validation {
  condition     = contains(["dev", "stage", "prod"], var.instance_type)
  error_message = "instance_type must be either dev, stage or prod."
}
```

### Output

Exposes information from Terraform:

```hcl
output "instance_id" {
  value = aws_instance.my_instance.id
}
```

---

## 19. Cleanup

Destroy the resources created by this phase:

```bash
terraform destroy
```

Confirm with:

```text
yes
```
