# Random passwords for MongoDB and RabbitMQ
resource "random_password" "mongodb" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "rabbitmq" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager Secret for MongoDB
resource "aws_secretsmanager_secret" "mongodb" {
  name                    = "${var.project_name}-${var.environment}-mongodb-credentials"
  description             = "MongoDB credentials for ${var.environment}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "mongodb" {
  secret_id = aws_secretsmanager_secret.mongodb.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.mongodb.result
    host     = "mongodb.${var.environment}.${var.project_name}.local"
    port     = 27017
  })
}

# Secrets Manager Secret for RabbitMQ
resource "aws_secretsmanager_secret" "rabbitmq" {
  name                    = "${var.project_name}-${var.environment}-rabbitmq-credentials"
  description             = "RabbitMQ credentials for ${var.environment}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rabbitmq.result
    host     = "rabbitmq.${var.environment}.${var.project_name}.local"
    amqp_port = 5672
    management_port = 15672
  })
}
