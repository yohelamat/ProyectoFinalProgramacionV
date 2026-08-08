# 1. Empaquetar el código Python en un archivo ZIP
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../../../backend/handlers/api.py"
  output_path = "../../../backend/handlers/api.zip"
}

# 2. Crear el Rol IAM (Seguridad de menor privilegio)
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

# 3. Darle permiso básico a la función para guardar logs en CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 4. Crear la Función Lambda
resource "aws_lambda_function" "api_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-api-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "api.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  # Versión de Python a utilizar
  runtime          = "python3.12" 

  # NUEVO: Encender el rastreo de X-Ray
  tracing_config {
    mode = "Active"
  }
}

# Para conectarlo con API Gateway más adelante
output "lambda_arn" {
  value = aws_lambda_function.api_handler.invoke_arn
}
output "function_name" {
  value = aws_lambda_function.api_handler.function_name
}

# 5. Dar permiso a Lambda para escribir en AWS X-Ray
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}