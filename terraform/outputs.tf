output "frontend_bucket_name" {
  description = "S3 bucket to receive the frontend build files."
  value       = module.frontend.bucket_name
}

output "frontend_website_url" {
  description = "HTTP URL of the frontend website after its files are uploaded."
  value       = module.frontend.website_url
}

output "uploads_bucket_name" {
  description = "Private S3 bucket for uploaded photos and documents."
  value       = module.uploads.bucket_name
}

output "database_table_names" {
  description = "DynamoDB tables for users, repair requests, and related records."
  value       = module.database.table_names
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID for frontend authentication."
  value       = module.auth.user_pool_id
}

output "cognito_client_id" {
  description = "Public Cognito app client ID for the frontend."
  value       = module.auth.client_id
}

output "cognito_issuer_url" {
  description = "Cognito JWT issuer URL for API authentication."
  value       = module.auth.issuer_url
}

output "notifications_topic_arn" {
  description = "SNS topic for requester repair-status notifications."
  value       = module.notifications.topic_arn
}
