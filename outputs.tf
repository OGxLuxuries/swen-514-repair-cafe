output "frontend_bucket_name" {
  description = "S3 bucket to receive the frontend build files."
  value       = module.frontend.bucket_name
}

output "frontend_website_url" {
  description = "HTTP URL of the frontend website after its files are uploaded."
  value       = module.frontend.website_url
}
