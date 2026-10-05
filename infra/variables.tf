variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "fixit-lab"
}

variable "environment" {
  description = "Environment name (for example: dev, test, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region where infrastructure is deployed."
  type        = string
  default     = "us-east-1"
}

variable "website_bucket_name" {
  description = "Optional override for the static website bucket name."
  type        = string
  default     = null
}

variable "uploads_bucket_name" {
  description = "Optional override for the private uploads bucket name."
  type        = string
  default     = null
}

variable "status_notification_email" {
  description = "Optional email endpoint subscribed to status notifications (must be confirmed in SNS)."
  type        = string
  default     = null
}

variable "bedrock_model_id" {
  description = "Foundation model ID used by the application when generating volunteer-reviewable summaries."
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "enable_comprehend" {
  description = "Enable optional IAM permissions for future Comprehend use."
  type        = bool
  default     = false
}

variable "allowed_cors_origins" {
  description = "List of allowed CORS origins for the API Gateway HTTP API."
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
