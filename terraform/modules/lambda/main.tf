data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../../../backend/handlers/api.py"
  output_path = "../../../backend/handlers/api.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_least_privilege" {
  name = "${var.project_name}-${var.environment}-least-privilege"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/${var.project_name}-${var.environment}-db",
          "arn:aws:dynamodb:*:*:table/${var.project_name}-${var.environment}-db/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "api_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-api-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "api.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  runtime          = "python3.12" 

  tracing_config {
    mode = "Active"
  }
}

output "lambda_arn" {
  value = aws_lambda_function.api_handler.invoke_arn
}

output "function_name" {
  value = aws_lambda_function.api_handler.function_name
}