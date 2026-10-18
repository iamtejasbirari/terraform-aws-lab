output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.ec2_s3_readonly.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2_s3_readonly.arn
}

output "iam_policy_arn" {
  description = "ARN of the S3 read-only IAM policy"
  value       = aws_iam_policy.s3_readonly.arn
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_s3_readonly.name
}