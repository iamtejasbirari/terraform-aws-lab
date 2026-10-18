variable "aws_region" {
  description = "AWS region where Terraform resource will be created"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default = null
}

variable "environment" {
  description = "Environment name"
  type = string
  default = "dev"
}