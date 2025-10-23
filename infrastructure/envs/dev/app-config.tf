# Application configuration for ECS services: Secrets Manager and SSM Parameters
# This module deliberately creates empty Secrets (no initial version).
# Populate values after apply using AWS Console/CLI or extend Terraform later.

locals {
  name_prefix = "sdt-dev"
}

# ==========================
# Secrets Manager - Secrets
# ==========================
# JWT / Security
resource "aws_secretsmanager_secret" "jwt" {
  name        = "${local.name_prefix}-app-secrets-jwt"
  description = "JWT and HMAC secrets for backend"
}

# OAuth2 (Google)
resource "aws_secretsmanager_secret" "oauth_google" {
  name        = "${local.name_prefix}-app-secrets-oauth-google"
  description = "OAuth2 Google client credentials"
}

# Mail (SMTP)
resource "aws_secretsmanager_secret" "mail" {
  name        = "${local.name_prefix}-app-secrets-mail"
  description = "SMTP credentials"
}

# RabbitMQ credentials
resource "aws_secretsmanager_secret" "mq" {
  name        = "${local.name_prefix}-app-secrets-mq"
  description = "RabbitMQ username/password"
}

# Redis (optional password)
resource "aws_secretsmanager_secret" "redis" {
  name        = "${local.name_prefix}-app-secrets-redis"
  description = "Redis password if used"
}

# MongoDB per-domain users
resource "aws_secretsmanager_secret" "mongo_analytics" {
  name        = "${local.name_prefix}-app-secrets-mongo-analytics"
  description = "MongoDB analytics user/password"
}

resource "aws_secretsmanager_secret" "mongo_gamification" {
  name        = "${local.name_prefix}-app-secrets-mongo-gamification"
  description = "MongoDB gamification user/password"
}

resource "aws_secretsmanager_secret" "mongo_notification" {
  name        = "${local.name_prefix}-app-secrets-mongo-notification"
  description = "MongoDB notification user/password"
}

# Postgres per-schema users (optional, if using dedicated users per schema)
resource "aws_secretsmanager_secret" "postgres_schema_users" {
  name        = "${local.name_prefix}-app-secrets-postgres-schemas"
  description = "Postgres per-schema users/passwords (JSON)"
}

# ======================
# SSM Parameter Store
# ======================
# Non-secret configuration shared by services
resource "aws_ssm_parameter" "spring_profile" {
  name  = "/${local.name_prefix}/config/SPRING_PROFILES_ACTIVE"
  type  = "String"
  value = "dev"
}

resource "aws_ssm_parameter" "log_level" {
  name  = "/${local.name_prefix}/config/LOG_LEVEL"
  type  = "String"
  value = "INFO"
}

resource "aws_ssm_parameter" "aws_region" {
  name  = "/${local.name_prefix}/config/AWS_REGION"
  type  = "String"
  value = var.aws_region
}

# Internal service endpoints (match ECS service discovery naming or ALB)
resource "aws_ssm_parameter" "config_server_uri" {
  name  = "/${local.name_prefix}/endpoints/SPRING_CLOUD_CONFIG_URI"
  type  = "String"
  value = "http://${local.name_prefix}-config-server:8081"
}

resource "aws_ssm_parameter" "eureka_zone" {
  name  = "/${local.name_prefix}/endpoints/EUREKA_CLIENT_SERVICEURL_DEFAULTZONE"
  type  = "String"
  value = "http://${local.name_prefix}-discovery-server:8082/eureka/"
}

resource "aws_ssm_parameter" "base_url" {
  name  = "/${local.name_prefix}/endpoints/BASE_URL"
  type  = "String"
  value = "http://${module.ecs.alb_dns_name}"
}

# Database endpoints and names (non-secret)
resource "aws_ssm_parameter" "postgres_jdbc_base" {
  name  = "/${local.name_prefix}/db/JDBC_BASE"
  type  = "String"
  value = "jdbc:postgresql://${module.rds.db_instance_endpoint}:5432/skilltracker_db"
}

# Mongo DB names
resource "aws_ssm_parameter" "mongo_analytics_db" {
  name  = "/${local.name_prefix}/mongo/analytics_db"
  type  = "String"
  value = "analytics_db"
}

resource "aws_ssm_parameter" "mongo_gamification_db" {
  name  = "/${local.name_prefix}/mongo/gamification_db"
  type  = "String"
  value = "gamification_db"
}

resource "aws_ssm_parameter" "mongo_notification_db" {
  name  = "/${local.name_prefix}/mongo/notification_db"
  type  = "String"
  value = "notification_db"
}
