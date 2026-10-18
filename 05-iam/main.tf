resource "aws_iam_role" "ec2_s3_readonly" {
  name = "terraform-lab-ec2-s3-readonly"

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
}

resource "aws_iam_policy" "s3_readonly" {
  name        = "terraform-lab-s3-readonly"
  description = "Allows read-only access to S3"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_readonly" {
  name = "terraform-lab-ec2-s3-readonly"
  role = aws_iam_role.ec2_s3_readonly.name
}

resource "aws_iam_role_policy_attachment" "ec2_s3_readonly" {
  role       = aws_iam_role.ec2_s3_readonly.name
  policy_arn = aws_iam_policy.s3_readonly.arn
}