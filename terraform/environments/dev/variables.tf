variable "aws_region" {
  description = "Región principal de AWS para el despliegue"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue (ej. dev, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "workshops-versionfinal"
  type        = string
  default     = "workshops-versionfinal"  # 
}