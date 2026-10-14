output "api_base_url" {
  description = "Base URL for the HTTP API."
  value       = aws_apigatewayv2_api.repair.api_endpoint
}

output "health_check_url" {
  description = "Health-check endpoint URL."
  value       = "${aws_apigatewayv2_api.repair.api_endpoint}/health"
}

output "website_bucket_name" {
  description = "Static website bucket name."
  value       = aws_s3_bucket.website.bucket
}

output "website_bucket_endpoint" {
  description = "S3 static website endpoint (HTTP only)."
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "uploads_bucket_name" {
  description = "Private uploads bucket name."
  value       = aws_s3_bucket.uploads.bucket
}

output "repair_requests_table_name" {
  description = "DynamoDB table name for repair data."
  value       = aws_dynamodb_table.repair_requests.name
}

output "status_updates_topic_arn" {
  description = "SNS topic ARN for email status notifications."
  value       = aws_sns_topic.status_updates.arn
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID."
  value       = aws_cognito_user_pool.users.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool app client ID for the frontend."
  value       = aws_cognito_user_pool_client.web.id
}

output "lambda_health_function_name" {
  description = "Lambda function backing the health endpoint."
  value       = aws_lambda_function.health.function_name
}

output "bedrock_model_id" {
  description = "Configured Bedrock model ID passed to the application."
  value       = var.bedrock_model_id
}
