output "bucket_name" {
  description = "Private bucket name for uploaded photos and documents."
  value       = aws_s3_bucket.uploads.id
}

output "bucket_arn" {
  description = "Uploads bucket ARN for Lambda access permissions."
  value       = aws_s3_bucket.uploads.arn
}
