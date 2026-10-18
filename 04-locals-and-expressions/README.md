# Phase 4 - Locals, Expressions and Functions

## Objective

This phase teaches how Terraform **evaluates and transforms data**. Phase 3 showed how to read existing infrastructure with data sources. Here the focus shifts to the Terraform language itself: building reusable values, filtering and reshaping collections, and composing strings and maps.

A single `aws_instance` serves only as a simple practical target. No VPC, subnet, security group, or additional AWS resources are created; the default AWS networking is reused.

| Feature     | Demonstration                           |
| ----------- | --------------------------------------- |
| `locals {}` | Centralize reusable values              |
| `for`       | Transform a collection                  |
| `if`        | Filter a collection                     |
| `lookup()`  | Safely retrieve a value from a map      |
| `merge()`   | Combine maps                            |
| `join()`    | Convert a list into a string            |
| `format()`  | Build formatted strings                 |
| `try()`     | Safely handle missing/invalid expressions |

The Terraform logic in this phase generates:

- Instance name
- Common tags
- Environment-specific tags
- Filtered lists
- Merged maps
- Formatted values

---

## Directory Structure

```text
04-locals-and-expressions/
├── main.tf
├── provider.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```

| File                       | Role                                              |
| -------------------------- | ------------------------------------------------- |
| `variables.tf`             | Inputs: `environment` and `features`              |
| `locals.tf`                | All the expression logic lives here               |
| `main.tf`                  | AMI data source and the EC2 instance              |
| `outputs.tf`               | Exposes the computed values so they can be inspected |
| `terraform.tfvars.example` | Example input values                              |

---

## 1. `locals {}`

A `locals` block defines named values that are computed once and reused throughout the module.

Unlike variables, locals are **not inputs**. They cannot be set from `terraform.tfvars` or the command line. They exist to avoid repeating expressions.

```hcl
locals {
  project_name = "terraform-aws-lab"
  environment  = var.environment
}
```

Locals are referenced with `local.<name>` (singular `local`, not `locals`):

```hcl
local.project_name
```

Locals can reference variables, other locals, and the results of functions:

```hcl
common_tags = {
  Project     = local.project_name
  Environment = local.environment
  ManagedBy   = "Terraform"
}
```

**Used in this project:** `locals.tf` defines `project_name`, `environment`, `common_tags`, `environment_tags`, `tags`, `name_parts`, `instance_name`, `description`, `enabled_features`, and `optional_owner`. Every other file consumes them through `local.*`.

```text
Variable (input)  →  Local (computed value)  →  Resource / Output
```

---

## 2. `for` Expression

A `for` expression transforms one collection into another.

Basic list example:

```hcl
[for name in ["a", "b", "c"] : upper(name)]
```

Result:

```text
["A", "B", "C"]
```

When iterating over a map, you can capture both the key and the value:

```hcl
[for key, value in var.features : key]
```

The brackets decide the output type:

| Syntax                              | Result |
| ----------------------------------- | ------ |
| `[for ... : ...]`                   | list   |
| `{for ... : key => value}`          | map    |

**Used in this project:** `enabled_features` iterates over the `var.features` map:

```hcl
enabled_features = [
  for feature, enabled in var.features : feature
  if enabled
]
```

Here `feature` is the map key (for example `monitoring`) and `enabled` is the boolean value. The expression returns the keys as a list.

---

## 3. `if` Expression

In a `for` expression, `if` acts as a **filter**. Only elements for which the condition is `true` are included in the result.

```hcl
[for n in [1, 2, 3, 4] : n if n > 2]
```

Result:

```text
[3, 4]
```

`if` is not a standalone statement in Terraform. It always appears as the trailing clause of a `for` expression.

> The `condition ? true_value : false_value` form is a different construct, called the conditional expression. It is not used in this phase.

**Used in this project:** the same `enabled_features` expression filters the feature map:

```hcl
[for feature, enabled in var.features : feature if enabled]
```

With the default values:

```hcl
features = {
  monitoring = true
  backup     = false
  logging    = true
}
```

the filter works like this:

```text
backup     = false  →  excluded
logging    = true   →  included
monitoring = true   →  included
```

Result:

```text
["logging", "monitoring"]
```

Terraform iterates map keys in lexical (alphabetical) order, so the result is sorted by key.

---

## 4. `lookup()`

`lookup()` retrieves a value from a map by key, and returns a **default** if the key does not exist.

```hcl
lookup(map, key, default)
```

Example:

```hcl
lookup({ a = 1, b = 2 }, "c", 0)
```

Result:

```text
0
```

Without the default, a missing key would cause an error.

**Used in this project:** `lookup()` selects the environment-specific tags:

```hcl
environment_tags = {
  dev = {
    Owner = "platform"
  }

  prod = {
    Owner = "production"
  }
}

lookup(local.environment_tags, local.environment, {})
```

| `environment` | Result                       |
| ------------- | ---------------------------- |
| `dev`         | `{ Owner = "platform" }`     |
| `prod`        | `{ Owner = "production" }`   |
| `staging`     | `{}` (the default)           |

An unknown environment such as `staging` does not break the configuration. It simply contributes no extra tags.

---

## 5. `merge()`

`merge()` combines multiple maps into one. If the same key appears in more than one map, **the later map wins**.

```hcl
merge({ a = 1, b = 2 }, { b = 3, c = 4 })
```

Result:

```text
{ a = 1, b = 3, c = 4 }
```

**Used in this project:** `merge()` appears twice.

First, in `locals.tf`, to combine common tags with environment-specific tags:

```hcl
tags = merge(
  local.common_tags,
  lookup(local.environment_tags, local.environment, {})
)
```

Then, in `main.tf`, to add the `Name` tag on top of the shared tags:

```hcl
tags = merge(
  local.tags,
  {
    Name = local.instance_name
  }
)
```

Final tags for `environment = "dev"`:

```text
Project     = "terraform-aws-lab"
Environment = "dev"
ManagedBy   = "Terraform"
Owner       = "platform"
Name        = "terraform-aws-lab-dev-instance"
```

---

## 6. `join()`

`join()` converts a list of strings into a single string using a separator.

```hcl
join("-", ["a", "b", "c"])
```

Result:

```text
"a-b-c"
```

**Used in this project:** `join()` builds the instance name from a list of parts:

```hcl
name_parts = [
  local.project_name,
  local.environment,
  "instance"
]

instance_name = join("-", local.name_parts)
```

Result for `dev`:

```text
"terraform-aws-lab-dev-instance"
```

Keeping the parts in a list makes the naming convention easy to read and change.

---

## 7. `format()`

`format()` builds a string from a template, similar to `printf`. Each `%s` is replaced by the next argument.

```hcl
format("%s has %d items", "cart", 3)
```

Result:

```text
"cart has 3 items"
```

Common verbs:

| Verb | Meaning        |
| ---- | -------------- |
| `%s` | string         |
| `%d` | integer        |
| `%f` | floating point |

**Used in this project:** `format()` builds the description:

```hcl
description = format(
  "%s %s EC2 instance",
  local.project_name,
  local.environment
)
```

Result for `dev`:

```text
"terraform-aws-lab dev EC2 instance"
```

`join()` vs `format()`:

```text
join()    → combine a LIST of items with a separator
format()  → fill placeholders in a TEMPLATE
```

---

## 8. `try()`

`try()` evaluates its arguments in order and returns the first one that does not produce an error. It is used to handle values that might be missing or invalid.

```hcl
try(expression, fallback)
```

Example:

```hcl
try(local.tags["Owner"], "unknown")
```

- If the `Owner` key exists, its value is returned.
- If it does not, the lookup would normally fail, so `try()` returns `"unknown"`.

**Used in this project:** `optional_owner` safely reads the `Owner` tag:

```hcl
optional_owner = try(local.tags["Owner"], "unknown")
```

| `environment` | `optional_owner` |
| ------------- | ---------------- |
| `dev`         | `"platform"`     |
| `prod`        | `"production"`   |
| `staging`     | `"unknown"`      |

For `staging`, `lookup()` returned `{}`, so no `Owner` tag was merged in. `try()` turns what would be an error into a clean fallback value.

---

## How Everything Works Together

```text
variables.tf
   │
   ├── var.environment ─────────────────────────────┐
   │                                                │
   └── var.features ──► for + if ──► enabled_features
                                                    │
locals.tf                                           │
   │                                                │
   ├── common_tags ──────┐                          │
   │                     │                          │
   ├── environment_tags ─┴─► lookup() ─► merge() ─► tags ──► try() ─► optional_owner
   │                                                │
   ├── name_parts ──► join() ──► instance_name      │
   │                                                │
   └── project_name + environment ──► format() ──► description
                                                    │
main.tf                                             │
   │                                                │
   └── aws_instance.this                            │
          ├── ami  ◄── data.aws_ami.amazon_linux.id │
          └── tags ◄── merge(local.tags, { Name })  │
                                                    │
outputs.tf                                          │
   └── instance_name, description, enabled_features, owner, tags ◄─┘
```

Step by step:

1. `var.environment` and `var.features` provide the inputs.
2. `locals.tf` transforms them: `lookup()` picks environment tags, `merge()` combines tag maps, `join()` and `format()` build strings, and `for`/`if` filters the feature flags.
3. `try()` safely reads an optional value from the result.
4. `main.tf` consumes `local.tags` and `local.instance_name` to configure the EC2 instance.
5. `outputs.tf` exposes the computed values so you can verify the logic without inspecting AWS.

The key point is that most of the work happens **inside Terraform**, before any AWS API call is made.

---

## Terraform Commands

Copy the example variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Initialize, format, and validate:

```bash
terraform init
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

View all outputs:

```bash
terraform output
```

Query individual outputs:

```bash
terraform output instance_name
terraform output enabled_features
terraform output owner
terraform output tags
```

### Expected output (default values)

```text
description = "terraform-aws-lab dev EC2 instance"
enabled_features = [
  "logging",
  "monitoring",
]
instance_name = "terraform-aws-lab-dev-instance"
owner = "platform"
tags = {
  "Environment" = "dev"
  "ManagedBy" = "Terraform"
  "Owner" = "platform"
  "Project" = "terraform-aws-lab"
}
```

### Experiment with `terraform console`

`terraform console` evaluates expressions interactively and is the fastest way to learn these functions.

```bash
terraform console
```

```text
> local.instance_name
> local.enabled_features
> join("-", ["a", "b", "c"])
> format("%s-%d", "web", 3)
> merge({ a = 1 }, { b = 2 })
> lookup({ a = 1 }, "z", 0)
> try(local.tags["Missing"], "fallback")
```

Exit:

```text
exit
```

### Try other inputs

Change `terraform.tfvars` and re-run `terraform plan`:

```hcl
environment = "prod"
```

`Owner` becomes `production`.

```hcl
environment = "staging"
```

`lookup()` falls back to `{}`, no `Owner` tag is added, and `try()` returns `"unknown"`.

```hcl
features = {
  monitoring = false
  backup     = true
  logging    = false
}
```

`enabled_features` becomes `["backup"]`.

### Cleanup

```bash
terraform destroy
```

Confirm with:

```text
yes
```

---

## What We Learned

- `locals {}` centralizes reusable values and avoids repeating expressions
- Locals are internal computed values, not inputs like variables
- `for` expressions transform a collection into a new list or map
- `if` inside a `for` expression filters the collection
- `lookup()` retrieves a value from a map and returns a default when the key is missing
- `merge()` combines maps, and later maps override earlier ones
- `join()` converts a list into a string
- `format()` builds strings from a template
- `try()` returns a fallback instead of failing on a missing or invalid expression
- Terraform evaluates and transforms data before it calls any cloud API
- The EC2 instance is only a practical target; the real subject of this phase is the Terraform language
