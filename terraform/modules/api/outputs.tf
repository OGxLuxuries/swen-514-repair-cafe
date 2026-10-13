output "api_id" {
  description = "HTTP API identifier."
  value       = aws_apigatewayv2_api.backend.id
}

output "api_url" {
  description = "HTTPS base URL for frontend API requests."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "route_keys" {
  description = "Authenticated method/path combinations the Python backend must implement."
  value       = sort(tolist(local.routes))
}
