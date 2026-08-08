variable "project_name" {}
variable "environment" {}

# 1. Creamos el Bucket S3 Privado (le agregué 'yohel' para que el nombre sea único en el mundo)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = "${var.project_name}-${var.environment}-webapp-yohel"
  force_destroy = true 
}

resource "aws_s3_bucket_public_access_block" "frontend_access" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Subimos tu index.html automáticamente al bucket
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "index.html"
  source       = "../../../frontend/index.html"
  content_type = "text/html"
}

# 3. Creamos la seguridad OAC (Para que solo CloudFront pueda leer el S3)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "Politica OAC para S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4. Creamos la Distribución de CloudFront (El CDN global)
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "S3Origin"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 5. Política que autoriza a CloudFront a entrar al Bucket S3
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

# 6. Esto nos imprimirá en la terminal la URL final para tomar la foto
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}