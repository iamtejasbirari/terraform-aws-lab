# Phase 7 — EC2

## Objective

Create your first real compute infrastructure: an EC2 instance, with every supporting piece written **explicitly**. No module is used yet. The goal is to understand how the EC2 pieces connect.

## Architecture

```text
Terraform
    │
    ├── Security Group
    ├── IAM Role (+ Instance Profile)
    ├── AMI (data source)
    │
    └── EC2
```

> No VPC resource is created in this phase. The security group and instance are placed in the account's **default VPC**.

## What This Phase Demonstrates

- AMI lookup
- Instance type
- Key pair
- Security group
- IAM instance profile
- User data
- Tags
- Outputs
- The dependency graph

## Directory Structure

```text
07-ec2/
├── provider.tf
├── variables.tf
├── data.tf
├── sg.tf
├── iam.tf
├── ec2.tf
├── outputs.tf
└── README.md
```

| File                | Role                                              |
| ------------------- | ------------------------------------------------- |
| `provider.tf`       | Terraform and AWS provider configuration          |
| `variables.tf`      | Inputs: region, instance type, key pair, project name |
| `data.tf`           | Looks up the Ubuntu AMI                           |
| `sg.tf`             | Network access rules                              |
| `iam.tf`            | IAM role, policy attachment, instance profile     |
| `ec2.tf`            | The EC2 instance                                  |
| `outputs.tf`        | Exposes useful values after apply                 |

---

## 1. `provider.tf`

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

---

## 2. `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region where the EC2 instance will be created"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "managed_by" {
  description = "EC2 instance managed by"
  type        = string
  default     = "Terraform"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
  default     = "terraform-aws-lab"
}
```

### Important

`key_name` is the **AWS EC2 Key Pair name**, not the local `.pem` filename.

For example:

```text
AWS Key Pair:
terraform-lab-key

Local private key:
terraform-lab-key.pem
```

The key pair must already exist in the chosen region. Terraform does not create it in this phase.

---

## 3. `data.tf`

Use a data source to find the Ubuntu AMI rather than hardcoding an AMI ID.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
```

Setting `owners` ensures Terraform only considers official images.

This demonstrates an important Terraform concept:

```text
Hardcoded AMI ID
      ↓
fragile

aws_ami data source
      ↓
dynamically discover current AMI
```

---

## 4. `sg.tf`

For the first EC2 project, the security group is created explicitly.

```hcl
resource "aws_security_group" "sg_ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for Terraform EC2 lab"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-ec2-sg"
    Project = var.project_name
    ManagedBy = var.managed_by
  }
}
```

> ⚠️ **Lab only:** SSH from `0.0.0.0/0` exposes port 22 publicly. Later we will restrict this to our own IP.

Note that `ingress` and `egress` are **nested blocks** (no `=`), while `tags` is a map argument (with `=`).

---

## 5. `iam.tf`

Creates an EC2 IAM role and instance profile.

```hcl
resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.project_name}-ec2-iam-role"

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

  tags = {
    Name      = "${var.project_name}-ec2-iam"
    Project   = var.project_name
    ManagedBy = var.managed_by
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_iam_role.name
}
```

The role's trust policy lets the EC2 service assume it, and the attached AWS-managed policy `AmazonSSMManagedInstanceCore` allows the instance to be managed through AWS Systems Manager.

The important chain here is:

```text
IAM Role
   ↓
Instance Profile
   ↓
EC2
```

The EC2 instance does not directly receive the IAM role. It receives the **instance profile**, which wraps the role.

---

## 6. `ec2.tf`

```hcl
resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data = <<-EOF
              #!/bin/bash

              apt-get update -y
              apt-get install -y nginx

              systemctl enable nginx
              systemctl start nginx

              echo "Terraform EC2 Lab" > /var/www/html/index.html
              EOF

  tags = {
    Name    = "${var.project_name}-ec2"
    Project = var.project_name
  }
}
```

### What this demonstrates

```text
ami
│
├── data.aws_ami.ubuntu.id
│
instance_type
│
├── var.instance_type
│
key_name
│
├── var.key_name
│
security group
│
├── aws_security_group.ec2.id
│
IAM
│
└── aws_iam_instance_profile.ec2.name
│
user_data
│
└── bootstrap EC2 after launch
```

| Argument                 | Value                                           | Source             |
| ------------------------ | ----------------------------------------------- | ------------------ |
| `ami`                    | `data.aws_ami.ubuntu.id`                        | Data source        |
| `instance_type`          | `var.instance_type`                             | Variable           |
| `key_name`               | `var.key_name`                                  | Variable           |
| `vpc_security_group_ids` | `[aws_security_group.sg_ec2.id]`                | Resource           |
| `iam_instance_profile`   | `aws_iam_instance_profile.ec2_iam_role.name`    | Resource           |
| `user_data`              | Bootstrap script installing Nginx               | Inline heredoc     |

`user_data` runs once at first boot. Here it installs Nginx and writes a simple home page.

---

## 7. `outputs.tf`

```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ubuntu.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.ubuntu.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ubuntu.public_dns
}

output "ami_id" {
  description = "AMI used by the EC2 instance"
  value       = data.aws_ami.ubuntu.id
}

output "security_group_id" {
  description = "Security group attached to the EC2 instance"
  value       = aws_security_group.ec2.id
}

output "iam_role_name" {
  description = "IAM role attached through the instance profile"
  value       = aws_iam_role.ec2.name
}
```

---

## 8. `terraform.tfvars`

Create this locally but **do not commit it**:

```hcl
aws_region    = "ap-south-1"
instance_type = "t3.micro"
key_name      = "YOUR_EXISTING_KEY_PAIR_NAME"
project_name  = "terraform-aws-lab"
```

For example:

```hcl
key_name = "terraform-lab-key"
```

Add this to `.gitignore`:

```text
terraform.tfvars
.terraform/
*.tfstate
*.tfstate.*
crash.log
```

---

## 9. Validate and Deploy

From the phase directory:

```bash
cd 07-ec2
```

Initialize:

```bash
terraform init
```

Format and validate:

```bash
terraform fmt
terraform validate
```

Check the execution plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

---

## 10. Verify

Get the outputs:

```bash
terraform output
```

Check the instance:

```bash
terraform output instance_id
```

Check the public IP:

```bash
terraform output instance_public_ip
```

Test Nginx:

```bash
curl http://$(terraform output -raw instance_public_ip)
```

Expected:

```text
Terraform EC2 Lab
```

> **Note:** the security group above only allows SSH (port 22), so this `curl` will time out. To reach Nginx from outside, add an HTTP rule to the security group:
>
> ```hcl
> ingress {
>   description = "HTTP"
>   from_port   = 80
>   to_port     = 80
>   protocol    = "tcp"
>   cidr_blocks = ["0.0.0.0/0"]
> }
> ```
>
> Also allow a minute or two after launch for `user_data` to finish installing Nginx.

You can also verify the user-data installation over SSH:

```bash
ssh -i <key>.pem ubuntu@$(terraform output -raw instance_public_ip)
```

Then:

```bash
systemctl status nginx
```

---

## 11. Dependency Graph

The requested architecture becomes:

```text
                    ┌──────────────────┐
                    │   AWS AMI Data   │
                    │ aws_ami.ubuntu   │
                    └────────┬─────────┘
                             │
                             │ ami
                             ▼
┌─────────────────┐   ┌──────────────────┐
│   IAM Role      │   │  Security Group  │
│                 │   │                  │
│ ec2             │   │ ec2              │
└────────┬────────┘   └────────┬─────────┘
         │                     │
         ▼                     │
┌─────────────────┐            │
│ Instance Profile│            │
│                 │            │
│ ec2             │            │
└────────┬────────┘            │
         │                     │
         └──────────┬──────────┘
                    │
                    ▼
             ┌──────────────┐
             │ EC2 Instance │
             │              │
             │ aws_instance │
             └──────┬───────┘
                    │
                    ▼
               Public IP
```

Generate the actual Terraform graph with:

```bash
terraform graph
```

For a visual graph:

```bash
terraform graph | dot -Tpng > graph.png
```

This requires Graphviz:

```bash
sudo apt install graphviz
```

---

## 12. Key Terraform Dependency Lesson

Notice that we never manually told Terraform the order:

```text
AMI → EC2
Security Group → EC2
IAM Profile → EC2
```

Terraform discovers these dependencies from references such as:

```hcl
ami = data.aws_ami.ubuntu.id
```

```hcl
vpc_security_group_ids = [
  aws_security_group.ec2.id
]
```

```hcl
iam_instance_profile = aws_iam_instance_profile.ec2.name
```

So the configuration itself creates the dependency graph:

```text
data.aws_ami.ubuntu
        │
        ▼
aws_instance.ubuntu
        ▲
        │
aws_security_group.ec2

aws_iam_instance_profile.ec2
        ▲
        │
aws_iam_role.ec2
```

(`aws_iam_instance_profile.ec2` also feeds into `aws_instance.ubuntu`, as shown in the diagram in section 11.)

> `aws_iam_role_policy_attachment.ssm` is **not** referenced by the instance, so Terraform does not force it to finish first. It is created in parallel with the other resources.

---

## Cleanup

```bash
terraform destroy
```

Confirm with:

```text
yes
```

---

## Key Takeaways

- Write EC2 infrastructure explicitly before abstracting it into a module
- Use the `aws_ami` data source instead of hardcoding AMI IDs
- `key_name` is the AWS key pair name, not the `.pem` filename
- An EC2 instance gets an IAM role through an **instance profile**
- `user_data` bootstraps the instance on first boot
- Terraform builds the dependency graph automatically from references
- Never commit `terraform.tfvars` or state files
- SSH open to `0.0.0.0/0` is for the lab only