variable "project_name" {}
variable "environment" {}

resource "aws_dynamodb_table" "main_table" {
  name           = "${var.project_name}-${var.environment}-db"
  billing_mode   = "PAY_PER_REQUEST" 
  
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }
  
  attribute {
    name = "SK"
    type = "S"
  }
  
  attribute {
    name = "GSI1PK"
    type = "S"
  }
  
  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name               = "GSI1"
    hash_key           = "GSI1PK"
    range_key          = "GSI1SK"
    projection_type    = "ALL"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

output "table_name" {
  value = aws_dynamodb_table.main_table.name
}