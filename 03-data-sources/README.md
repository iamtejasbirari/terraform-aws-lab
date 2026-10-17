# Terraform Data Sources

This phase introduces data sources: how Terraform reads existing infrastructure (an Amazon Linux AMI) and feeds it into a resource it manages (an EC2 instance).

## Table of Contents

- [Resources vs Data Sources](#resources-vs-data-sources)
- [Data Source](#data-source)
- [Example Used in This Phase](#example-used-in-this-phase)
- [Why Use Data Sources?](#why-use-data-sources)
- [Resource vs Data Source](#resource-vs-data-source)
- [Terraform Workflow](#terraform-workflow)
- [Commands](#commands)
- [Verify the Data Source](#verify-the-data-source)
- [Important Concept](#important-concept)
- [Key Takeaways](#key-takeaways)
- [Run](#run)
- [Reusable Pattern](#reusable-pattern)

---

## Resources vs Data Sources

Terraform is responsible for managing the EC2 instance. Conceptually:

```text
Terraform
    │
    │ Create / Update / Delete
    ↓
AWS Resource
```

---

## Data Source

A data source allows Terraform to query information that already exists.

Example:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
```

Terraform does not create this AMI. It asks AWS:

```text
"Find me the most recent Amazon Linux AMI
matching these conditions."
```

Conceptually:

```text
Terraform
    │
    │ Read / Query
    ↓
Existing AWS Resource
```

---

## Example Used in This Phase

This project uses an Amazon Linux AMI data source:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

The data source searches AWS for an existing AMI. The resulting AMI ID can then be consumed by another Terraform resource:

```hcl
resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
}
```

The important syntax is:

```text
data.<type>.<name>.<attribute>
```

In this example:

```text
data.aws_ami.amazon_linux.id
```

means:

```text
data
 │
 └── aws_ami
       │
       └── amazon_linux
              │
              └── id
```

---

## Why Use Data Sources?

Data sources are useful when Terraform needs information about infrastructure that Terraform does not manage.

Common examples include:

```text
Existing AMI
Existing VPC
Existing subnet
Existing security group
Existing AWS account
Existing availability zones
Existing IAM policy
```

For example:

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

Terraform can then consume:

```text
data.aws_availability_zones.available.names
```

---

## Resource vs Data Source

|                              | Resource      | Data Source  |
| ---------------------------- | ------------- | ------------ |
| **Purpose**                  | Create/manage | Read/query   |
| **Creates infrastructure**   | Yes           | No           |
| **Terraform manages lifecycle** | Yes        | No           |
| **Example**                  | `aws_instance` | `aws_ami`   |
| **Syntax**                   | `resource`    | `data`       |
| **Typical use**              | Create EC2    | Find AMI     |

### Simple rule

```text
resource → Terraform manages it

data → Terraform reads it
```

---

## Terraform Workflow

The configuration in this phase creates the following dependency:

```text
                 AWS
                  │
                  │ Query
                  ↓
          ┌─────────────────┐
          │ aws_ami data    │
          │ source          │
          └────────┬────────┘
                   │
                   │ AMI ID
                   ↓
          ┌─────────────────┐
          │ aws_instance    │
          │ resource        │
          └────────┬────────┘
                   │
                   ↓
                EC2
```

Terraform understands that the EC2 instance depends on the AMI returned by the data source.

---

## Commands

Initialize the Terraform working directory:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Review the execution plan:

```bash
terraform plan
```

Apply the configuration:

```bash
terraform apply
```

Show the selected AMI:

```bash
terraform output selected_ami_id
```

Show the EC2 instance ID:

```bash
terraform output instance_id
```

---

## Verify the Data Source

You can inspect the selected AMI directly:

```bash
terraform console
```

Then:

```text
data.aws_ami.amazon_linux.id
```

Terraform should return an AMI ID.

Exit:

```text
exit
```

---

## Important Concept

A data source does not mean Terraform owns the object.

For example:

```hcl
data "aws_ami" "amazon_linux" {
  ...
}
```

does **not** mean:

```text
Terraform created the AMI
```

It means:

```text
Terraform queried AWS and obtained information about an existing AMI.
```

The EC2 instance, however, is a Terraform-managed resource:

```hcl
resource "aws_instance" "example" {
  ...
}
```

Therefore:

```text
AMI
 └── data source
      └── Read by Terraform

EC2
 └── resource
      └── Created and managed by Terraform
```

---

## Key Takeaways

1. `resource` is used to create and manage infrastructure.
2. `data` is used to read existing information.
3. Data sources do not create the objects they query.
4. Data source attributes can be consumed by resources.
5. `data.aws_ami.amazon_linux.id` provides the AMI ID used by the EC2 resource.
6. Data sources are essential when Terraform needs to integrate with infrastructure that already exists.

---

## Run

```bash
cd 03-data-sources

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

---

## Reusable Pattern

This phase gives you the fundamental pattern you'll reuse heavily later:

```hcl
data "..." "..." {
  # discover existing infrastructure
}

resource "..." "..." {
  # create/manage infrastructure

  some_argument = data....some_attribute
}
```

For the lab, do not hardcode AMI IDs when the value can be discovered through a data source.