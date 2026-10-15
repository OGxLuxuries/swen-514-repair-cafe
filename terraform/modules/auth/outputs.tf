output "user_pool_id" {
  description = "Cognito user pool ID for frontend authentication and sample-user setup."
  value       = aws_cognito_user_pool.users.id
}

output "user_pool_arn" {
  description = "Cognito user pool ARN for scoped IAM permissions."
  value       = aws_cognito_user_pool.users.arn
}

output "client_id" {
  description = "Public browser app client ID for the frontend and API Gateway JWT audience."
  value       = aws_cognito_user_pool_client.frontend.id
}

output "issuer_url" {
  description = "Cognito token issuer URL for the API Gateway JWT authorizer."
  value       = "https://${aws_cognito_user_pool.users.endpoint}"
}
