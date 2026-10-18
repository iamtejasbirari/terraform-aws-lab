output "bucket_name" {
  description = "Name of the S3 bucket"
  value = aws_s3_bucket.my_bucket.bucket
}

output "bucket_arn" {
  description = "ARN of S3 bucket"
  value = aws_s3_bucket.my_bucket.arn
}