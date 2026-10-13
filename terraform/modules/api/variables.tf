variable "name_prefix" {
  description = "Resource naming prefix, such as repair-cafe-dev."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name_prefix) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name_prefix))
    error_message = "Use 2-30 lowercase letters, digits, or hyphens; start with a letter and end with a letter or digit."
  }
}

variable "lambda_function_name" {
  description = "Backend Lambda function name for invocation permissions."
  type        = string
  nullable    = false
}

variable "lambda_invoke_arn" {
  description = "Backend Lambda invocation ARN for API Gateway integration."
  type        = string
  nullable    = false
}

variable "cognito_issuer_url" {
  description = "Cognito user pool JWT issuer URL, including https://."
  type        = string
  nullable    = false
}

variable "cognito_client_id" {
  description = "Cognito browser app client ID used to validate token audience/client_id."
  type        = string
  nullable    = false
}

variable "allowed_origins" {
  description = "Frontend origins allowed to make browser API requests, with no path or trailing slash."
  type        = list(string)
  nullable    = false

  validation {
    condition = length(var.allowed_origins) > 0 && alltrue([
      for origin in var.allowed_origins : can(regex("^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$", origin))
    ])
    error_message = "Provide at least one explicit HTTP or HTTPS origin without wildcards, paths, or trailing slashes."
  }
}
