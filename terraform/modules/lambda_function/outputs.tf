output "function_name" {
  description = "Backend Lambda function name for API invocation permissions."
  value       = aws_lambda_function.backend.function_name
}

output "function_arn" {
  description = "Backend Lambda function ARN."
  value       = aws_lambda_function.backend.arn
}

output "invoke_arn" {
  description = "Lambda invocation ARN for the API Gateway integration."
  value       = aws_lambda_function.backend.invoke_arn
}

output "log_group_name" {
  description = "CloudWatch log group for backend troubleshooting."
  value       = aws_cloudwatch_log_group.backend.name
}
