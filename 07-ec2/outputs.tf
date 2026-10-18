output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ubuntu.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.ubuntu.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ubuntu.public_dns
}

output "ami_id" {
  description = "AMI used by the EC2 instance"
  value       = data.aws_ami.ubuntu.id
}

output "security_group_id" {
  description = "Security group attached to the EC2 instance"
  value       = aws_security_group.sg_ec2.id
}

output "iam_role_name" {
  description = "IAM role attached through the instance profile"
  value       = aws_iam_role.ec2_iam_role.name
}