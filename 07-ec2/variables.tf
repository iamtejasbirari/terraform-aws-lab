variable "aws_region" {
  description = "AWS region where Terraform resource will be created"
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

variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
  default     = "terraform-aws-lab"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name"
  type        = string
}