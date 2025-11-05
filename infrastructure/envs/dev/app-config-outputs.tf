# Outputs for app configuration secrets and parameters

output "app_secrets_arns" {
  description = "ARNs of application Secrets Manager secrets"
  value = {
    jwt                = aws_secretsmanager_secret.jwt.arn
    oauth_google       = aws_secretsmanager_secret.oauth_google.arn
    mail               = aws_secretsmanager_secret.mail.arn
    mq                 = aws_secretsmanager_secret.mq.arn
    redis              = aws_secretsmanager_secret.redis.arn
    mongo_analytics    = aws_secretsmanager_secret.mongo_analytics.arn
    mongo_gamification = aws_secretsmanager_secret.mongo_gamification.arn
    mongo_notification = aws_secretsmanager_secret.mongo_notification.arn
    postgres_schemas   = aws_secretsmanager_secret.postgres_schema_users.arn
  }
}

output "app_ssm_params" {
  description = "SSM Parameter names for non-secret configuration"
  value = {
    SPRING_PROFILES_ACTIVE               = aws_ssm_parameter.spring_profile.name
    LOG_LEVEL                            = aws_ssm_parameter.log_level.name
    AWS_REGION                           = aws_ssm_parameter.aws_region.name
    SPRING_CLOUD_CONFIG_URI              = aws_ssm_parameter.config_server_uri.name
    EUREKA_CLIENT_SERVICEURL_DEFAULTZONE = aws_ssm_parameter.eureka_zone.name
    BASE_URL                             = aws_ssm_parameter.base_url.name
    JDBC_BASE                            = aws_ssm_parameter.postgres_jdbc_base.name
    MONGO_ANALYTICS_DB                   = aws_ssm_parameter.mongo_analytics_db.name
    MONGO_GAMIFICATION_DB                = aws_ssm_parameter.mongo_gamification_db.name
    MONGO_NOTIFICATION_DB                = aws_ssm_parameter.mongo_notification_db.name
  }
}
