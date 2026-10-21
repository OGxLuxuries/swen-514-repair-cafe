data "archive_file" "textract_lambda_zip" {
  type        = "zip"
  source_file = var.source_file
  output_path = "${path.module}/.terraform/tmp/${var.function_name}.zip"
}

resource "aws_iam_role" "textract_lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "textract_lambda_logs" {
  role       = aws_iam_role.textract_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "textract_only" {
  name = "${var.function_name}-textract-policy"
  role = aws_iam_role.textract_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["textract:DetectDocumentText"]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "textract" {
  function_name    = var.function_name
  role             = aws_iam_role.textract_lambda_role.arn
  filename         = data.archive_file.textract_lambda_zip.output_path
  source_code_hash = data.archive_file.textract_lambda_zip.output_base64sha256

  handler     = "handler.lambda_handler"
  runtime     = "python3.12"
  timeout     = 29
  memory_size = 256
}