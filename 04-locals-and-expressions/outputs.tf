output "instance_name" {
  description = "Generated EC2 instance name"
  value       = local.instance_name
}

output "description" {
  description = "Generated description"
  value       = local.description
}

output "enabled_features" {
  description = "Features enabled through the feature map"
  value       = local.enabled_features
}

output "owner" {
  description = "Owner retrieved using try()"
  value       = local.optional_owner
}

output "tags" {
  description = "Final merged tags"
  value       = local.tags
}