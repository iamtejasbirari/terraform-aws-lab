locals {
  project_name = "terraform-aws-lab"
  environment = var.environment

  common_tags = {
    Project = local.project_name
    Environment = local.environment
    ManagedBy = "Terraform"
  }

  environment_tags = {
    dev = {
        Owner = "platform"
    }

    prod = {
        Owner = "production"
    }
  }

  tags = merge(
    local.common_tags,
    lookup(local.environment_tags, local.environment, {})
  )

  name_parts = [
    local.project_name,
    local.environment,
    "instance"
  ]

  instance_name = join("-", local.name_parts)

  description = format(
    "%s %s EC2 instance", 
    local.project_name,
    local.environment
  )

  enabled_features = [
    for feature, enabled in var.features : feature
    if enabled
  ]

  optional_owner = try(local.tags["Owner"], "unknown")
}