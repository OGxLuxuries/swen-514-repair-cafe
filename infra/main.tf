provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  website_bucket_name = coalesce(var.website_bucket_name, format("%s-%s-frontend-%s", var.project_name, var.environment, data.aws_caller_identity.current.account_id))
  uploads_bucket_name = coalesce(var.uploads_bucket_name, format("%s-%s-uploads-%s", var.project_name, var.environment, data.aws_caller_identity.current.account_id))

  bedrock_model_arn = format("arn:aws:bedrock:%s::foundation-model/%s", var.aws_region, var.bedrock_model_id)
}

data "aws_caller_identity" "current" {}

data "archive_file" "health_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/health_check.py"
  output_path = "${path.module}/health_check.zip"
}

resource "aws_s3_bucket" "website" {
  bucket = local.website_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_public_read" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublicReadObjects"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

resource "aws_s3_bucket" "uploads" {
  bucket = local.uploads_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "repair_requests" {
  name         = "${var.project_name}-${var.environment}-repair-requests"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}

resource "aws_sns_topic" "status_updates" {
  name = "${var.project_name}-${var.environment}-status-updates"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.status_notification_email == null ? 0 : 1
  topic_arn = aws_sns_topic.status_updates.arn
  protocol  = "email"
  endpoint  = var.status_notification_email
}

resource "aws_cognito_user_pool" "users" {
  name = "${var.project_name}-${var.environment}-users"

  alias_attributes = ["email"]

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  tags = local.common_tags
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.project_name}-${var.environment}-web-client"
  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret                      = false
  explicit_auth_flows                  = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
  prevent_user_existence_errors        = "ENABLED"
  allowed_oauth_flows_user_pool_client = false
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cloudwatch_log_group" "lambda_health" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-health"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lambda_access" {
  name = "${var.project_name}-${var.environment}-lambda-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        {
          Sid    = "LambdaLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "${aws_cloudwatch_log_group.lambda_health.arn}:*"
        },
        {
          Sid    = "RepairTableAccess"
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:Query"
          ]
          Resource = [
            aws_dynamodb_table.repair_requests.arn,
            "${aws_dynamodb_table.repair_requests.arn}/index/*"
          ]
        },
        {
          Sid    = "UploadsBucketAccess"
          Effect = "Allow"
          Action = [
            "s3:ListBucket"
          ]
          Resource = aws_s3_bucket.uploads.arn
        },
        {
          Sid    = "UploadsObjectAccess"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = "${aws_s3_bucket.uploads.arn}/*"
        },
        {
          Sid    = "PublishStatusUpdates"
          Effect = "Allow"
          Action = [
            "sns:Publish"
          ]
          Resource = aws_sns_topic.status_updates.arn
        },
        {
          Sid    = "TextractRead"
          Effect = "Allow"
          Action = [
            "textract:AnalyzeDocument",
            "textract:DetectDocumentText"
          ]
          Resource = "*"
        },
        {
          Sid    = "BedrockInvokeConfiguredModel"
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream"
          ]
          Resource = local.bedrock_model_arn
        }
      ],
      var.enable_comprehend ? [
        {
          Sid    = "OptionalComprehend"
          Effect = "Allow"
          Action = [
            "comprehend:DetectDominantLanguage",
            "comprehend:DetectEntities",
            "comprehend:DetectKeyPhrases",
            "comprehend:DetectSentiment"
          ]
          Resource = "*"
        }
      ] : []
    )
  })
}

resource "aws_lambda_function" "health" {
  function_name = "${var.project_name}-${var.environment}-health"
  role          = aws_iam_role.lambda_execution.arn
  runtime       = "python3.12"
  handler       = "health_check.handler"

  filename         = data.archive_file.health_lambda_zip.output_path
  source_code_hash = data.archive_file.health_lambda_zip.output_base64sha256

  timeout     = 5
  memory_size = 128

  environment {
    variables = {
      ENVIRONMENT              = var.environment
      REPAIR_TABLE_NAME        = aws_dynamodb_table.repair_requests.name
      UPLOADS_BUCKET_NAME      = aws_s3_bucket.uploads.bucket
      STATUS_TOPIC_ARN         = aws_sns_topic.status_updates.arn
      COGNITO_USER_POOL_ID     = aws_cognito_user_pool.users.id
      COGNITO_USER_POOL_CLIENT = aws_cognito_user_pool_client.web.id
      BEDROCK_MODEL_ID         = var.bedrock_model_id
      ENABLE_COMPREHEND        = tostring(var.enable_comprehend)
    }
  }

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_group.lambda_health]
}

resource "aws_apigatewayv2_api" "repair" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.allowed_cors_origins
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "health_lambda" {
  api_id                 = aws_apigatewayv2_api.repair.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.health.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.repair.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health_lambda.id}"
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-api"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.repair.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId         = "$context.requestId"
      sourceIp          = "$context.identity.sourceIp"
      requestTime       = "$context.requestTime"
      routeKey          = "$context.routeKey"
      status            = "$context.status"
      protocol          = "$context.protocol"
      responseLength    = "$context.responseLength"
      integrationError  = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.repair.execution_arn}/*/*"
}
