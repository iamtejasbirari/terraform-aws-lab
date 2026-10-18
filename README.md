# Terraform AWS Lab

A hands-on Terraform and AWS learning repository covering Infrastructure as Code from beginner to advanced concepts.

Each numbered folder is a self-contained **phase**. A phase focuses on a small set of Terraform ideas, uses a simple AWS resource as the practical example, and includes its own `README.md` explaining the concepts.

## Table of Contents

- [Learning Path](#learning-path)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [How to Use a Phase](#how-to-use-a-phase)
- [Roadmap](#roadmap)
- [Safety and Cost Notes](#safety-and-cost-notes)
- [Git Hygiene](#git-hygiene)

---

## Learning Path

| Phase | Folder | Focus | AWS example |
| ----- | ------ | ----- | ----------- |
| 1 | [`01-terraform-basics`](./01-terraform-basics) | What Terraform is, providers, resources, the `init` → `plan` → `apply` → `destroy` workflow, state, dependency graph | S3 bucket |
| 2 | [`02-variables-and-outputs`](./02-variables-and-outputs) | Variables, types, defaults, `terraform.tfvars`, validation, outputs | EC2 instance |
| 3 | [`03-data-sources`](./03-data-sources) | Reading existing infrastructure with `data` blocks, resource vs data source | AMI lookup |
| 4 | [`04-locals-and-expressions`](./04-locals-and-expressions) | `locals`, `for`, `if`, `lookup()`, `merge()`, `join()`, `format()`, `try()` | EC2 instance (tags and naming) |
| 5 | [`05-iam`](./05-iam) | IAM roles, policies, trust vs permissions policy, instance profiles | IAM role for S3 read-only |
| 6 | [`06-s3`](./06-s3) | One bucket, variables and tags, arguments vs nested blocks | S3 bucket |
| 7 | [`07-ec2`](./07-ec2) | An explicit compute stack and how its pieces depend on each other | EC2 + security group + IAM profile |

### Phase highlights

**1. Terraform basics**
Declare a provider and a resource, run the core workflow, and learn what `.terraform/`, `.terraform.lock.hcl`, and `terraform.tfstate` are. Introduces desired state vs actual state and the dependency graph.

**2. Variables and outputs**
Replace hardcoded values with variables, supply them through `terraform.tfvars`, restrict them with `validation`, and expose results with outputs.

**3. Data sources**
Use `data "aws_ami"` instead of hardcoding AMI IDs. The rule of thumb: `resource` means Terraform manages it, `data` means Terraform reads it.

**4. Locals and expressions**
Learn how Terraform evaluates and transforms data: centralize values with `locals`, filter and reshape collections with `for`/`if`, and compose maps and strings with built-in functions.

**5. IAM**
Separate **identity, trust, and permissions**. Create a role with a trust policy, a permissions policy, an attachment, and an instance profile, so workloads use temporary credentials instead of access keys.

**6. S3**
Keep the focus on a single bucket while learning how arguments, maps, and nested blocks are written.

**7. EC2**
Build the compute stack explicitly, with no module yet: AMI lookup, instance type, key pair, security group, IAM instance profile, user data, tags, and outputs. Ends with the dependency graph Terraform derives from references.

---

## Repository Structure

```text
terraform-aws-lab/
├── 01-terraform-basics/
├── 02-variables-and-outputs/
├── 03-data-sources/
├── 04-locals-and-expressions/
├── 05-iam/
├── 06-s3/
├── 07-ec2/
├── .gitignore
└── README.md
```

Each phase is independent: it has its own configuration files, its own state, and its own `README.md`. Phases can be applied and destroyed on their own.

---

## Prerequisites

- An AWS account
- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.6.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), configured with credentials that can create the resources in each phase
- An existing EC2 key pair (needed for phase 7)

Verify your setup:

```bash
terraform version
aws sts get-caller-identity
```

Most phases default to the `ap-south-1` region.

---

## How to Use a Phase

Work through one phase at a time. Read its `README.md` first, then run:

```bash
cd 01-terraform-basics

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

When you are finished with the phase:

```bash
terraform destroy
```

The recommended loop for any change is:

```text
terraform fmt
      ↓
terraform validate
      ↓
terraform plan   ← review before applying
      ↓
terraform apply
```

Some phases need input values. Create a local `terraform.tfvars` (never commit it) or copy the provided `terraform.tfvars.example` if the phase includes one.

---

## Roadmap

**Terraform**

- [x] Providers
- [x] Resources
- [x] Variables
- [x] Outputs
- [x] Locals
- [x] Data Sources
- [x] Expressions
- [x] Functions
- [x] Dependencies
- [ ] Modules
- [ ] State
- [ ] Workspaces
- [ ] Lifecycle
- [ ] Import
- [ ] Testing

**AWS**

- [x] IAM
- [x] EC2
- [x] S3
- [ ] VPC
- [ ] ALB
- [ ] Auto Scaling
- [ ] CloudWatch
- [ ] DynamoDB
- [ ] Lambda

**Advanced**

- [ ] Remote State
- [ ] Reusable Modules
- [ ] Environment Management
- [ ] CI/CD
- [ ] Security
- [ ] Testing

---

## Safety and Cost Notes

- **Destroy when finished.** Run `terraform destroy` at the end of each phase so resources such as EC2 instances don't keep costing money.
- **S3 bucket names are globally unique.** Choose your own unique name when a phase asks for `bucket_name`.
- **The labs favor simplicity over hardening.** For example, phase 7 opens SSH to `0.0.0.0/0` for convenience. Restrict access to your own IP in anything beyond a throwaway lab.
- **Least privilege matters.** Policies in these labs may use broad resources such as `"*"` to keep examples short. Narrow them in real environments.

---

## Git Hygiene

Do not commit local state, provider binaries, or variable files that may hold sensitive values. Make sure your `.gitignore` includes:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
crash.log
crash.*.log
```

Do commit `.terraform.lock.hcl`, so everyone uses the same verified provider versions.

In production, Terraform state is normally stored remotely using a backend with access control and locking. Remote state is on the roadmap.