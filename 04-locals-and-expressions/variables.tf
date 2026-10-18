variable "environment" {
  description = "Deployment Environment"
  type = string
  default = "dev"
}
variable "features" {
  description = "Feature flags used to demonstrate for and if expressions"
  type = map(bool)

  default = {
    monitoring = true
    backup = false
    logging = true
  }
}