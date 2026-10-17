variable "aws_region" {
  description = "AWS region where Terraform resource will be created"
  type = string
  default = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID used to launch EC2 instance"
  type = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t3.micro"
}

variable "environment" {
  description = "Environment name"
  type = string
  default = "dev"

  validation {
    condition = contains(
        ["dev", "stage", "prod"],
        var.environment
    )

    error_message = "environment must be dev, stage or prod"
  }
}