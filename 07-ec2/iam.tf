resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.project_name}-ec2-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-ec2-iam"
    Project   = var.project_name
    ManagedBy = var.managed_by
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  role = aws_iam_role.ec2_iam_role.name
  name = "${var.project_name}-ec2-profile"
}