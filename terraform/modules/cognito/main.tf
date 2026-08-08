resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-user-pool"

  # Políticas de contraseña segura
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Iniciar sesión usando el correo
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

# Cliente de la aplicación (el frontend usará esto para conectarse)
resource "aws_cognito_user_pool_client" "client" {
  name            = "${var.project_name}-${var.environment}-app-client"
  user_pool_id    = aws_cognito_user_pool.main.id
  generate_secret = false
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# Imprimir los IDs en la terminal para conectarlos al frontend después
output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.main.arn
}