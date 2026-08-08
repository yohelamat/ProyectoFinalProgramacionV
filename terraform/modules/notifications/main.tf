# 1. Crear el Topic de SNS (El "megáfono" de las alertas)
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

# 2. Suscribir tu correo electrónico al Topic
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 3. Crear la Regla en EventBridge (Escucha cuando alguien crea un taller)
resource "aws_cloudwatch_event_rule" "workshop_rule" {
  name        = "${var.project_name}-${var.environment}-workshop-events"
  description = "Captura eventos de creacion de talleres"
  
  event_pattern = jsonencode({
    "source" : ["workshops.api"],
    "detail-type" : ["TallerCreado"]
  })
}

# 4. Cola SQS para capturar eventos fallidos (Dead Letter Queue)
resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-${var.environment}-dlq"
}

# 5. Conectar EventBridge con SNS (Cuando escuche el evento, dispara la alerta)
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.workshop_rule.name 
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn

  # NUEVO: Enviar eventos fallidos a la cola DLQ
  dead_letter_config {
    arn = aws_sqs_queue.dlq.arn
  }
}

# 6. Dar permiso a EventBridge para que pueda publicar en SNS
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action = "sns:Publish"
      Resource = aws_sns_topic.alerts.arn
    }]
  })
}

# 7. Gestor de Secretos (Secrets Manager) para credenciales simuladas
resource "aws_secretsmanager_secret" "external_api_keys" {
  name        = "${var.project_name}-${var.environment}-api-keys-v2"
  description = "Credenciales externas para integraciones de terceros"
}

resource "aws_secretsmanager_secret_version" "external_api_keys_value" {
  secret_id     = aws_secretsmanager_secret.external_api_keys.id
  secret_string = jsonencode({
    "THIRD_PARTY_API_KEY" = "valor-secreto-simulado-12345"
  })
}

# 8. Tarea Programada (Scheduler) para recordatorios 24h antes
resource "aws_cloudwatch_event_rule" "daily_reminder" {
  name                = "${var.project_name}-${var.environment}-daily-reminder"
  description         = "Ejecuta recordatorios de talleres 24h antes"
  schedule_expression = "cron(0 12 * * ? *)" # Todos los días a las 12:00 PM UTC
}

resource "aws_cloudwatch_event_target" "sns_reminder_target" {
  rule      = aws_cloudwatch_event_rule.daily_reminder.name
  target_id = "SendDailyReminderToSNS"
  arn       = aws_sns_topic.alerts.arn
}