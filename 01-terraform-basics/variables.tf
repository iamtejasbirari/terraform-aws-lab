variable "aws_region" {
  description = "AWS region where Terraform resource will be created"
  type = string
  default = "ap-south-1"
}

variable "bucket_name" {
  description = "Name of the S3 Bucket"
  type = string
  default = null
}