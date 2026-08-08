module "frontend" {
  source       = "../../modules/frontend"
  
  project_name = var.project_name
  environment  = var.environment
}

output "url_sitio_web" {
  value = module.frontend.cloudfront_url
}

module "cognito" {
  source       = "../../modules/cognito"
  
  project_name = var.project_name
  environment  = var.environment
}

module "database" {
  source       = "../../modules/database"
  
  project_name = var.project_name
  environment  = var.environment
}

module "lambda" {
  source       = "../../modules/lambda"
  
  project_name = var.project_name
  environment  = var.environment
}

module "api_gateway" {
  source                = "../../modules/api_gateway"
  
  project_name          = var.project_name
  environment           = var.environment
  
  # Conexiones con otros módulos
  lambda_invoke_arn     = module.lambda.lambda_arn
  function_name         = module.lambda.function_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
}

module "notifications" {
  source       = "../../modules/notifications"
  
  project_name = var.project_name
  environment  = var.environment
  alert_email  = "yohel26@gmail.com" 
}

module "waf" {
  source       = "../../modules/waf"
  project_name = var.project_name
  environment  = var.environment
}