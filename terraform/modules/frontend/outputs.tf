output "bucket_name" {
  description = "Bucket name used when deploying the frontend files."
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "Frontend bucket ARN for deployment permissions."
  value       = aws_s3_bucket.frontend.arn
}

output "website_url" {
  description = "HTTP URL of the S3 static website."
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}
