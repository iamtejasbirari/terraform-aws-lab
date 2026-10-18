resource "aws_security_group" "sg_ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security for Terraform EC2"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allowed all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-ec2-sg"
    Project   = var.project_name
    ManagedBy = var.managed_by
  }
}