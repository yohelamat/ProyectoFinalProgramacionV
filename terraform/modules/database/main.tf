variable "project_name" {}
variable "environment" {}

resource "aws_dynamodb_table" "main_table" {
  name           = "${var.project_name}-${var.environment}-db"
  
  # Modo Serverless: Solo pagas cuando la base de datos se usa (ideal para evitar costos extra)
  billing_mode   = "PAY_PER_REQUEST" 
  
  # Estructura del Single-Table Design
  hash_key       = "PK"  # Clave de Partición
  range_key      = "SK"  # Clave de Ordenamiento

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

output "table_name" {
  value = aws_dynamodb_table.main_table.name
}