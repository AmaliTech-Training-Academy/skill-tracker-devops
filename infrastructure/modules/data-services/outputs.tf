output "mongodb_service_name" {
  description = "DNS name for MongoDB service"
  value       = "mongodb.${var.environment}.${var.project_name}.local"
}

output "redis_service_name" {
  description = "DNS name for Redis service"
  value       = "redis.${var.environment}.${var.project_name}.local"
}

output "rabbitmq_service_name" {
  description = "DNS name for RabbitMQ service"
  value       = "rabbitmq.${var.environment}.${var.project_name}.local"
}

output "mongodb_secret_arn" {
  description = "ARN of MongoDB credentials secret"
  value       = aws_secretsmanager_secret.mongodb.arn
}

output "rabbitmq_secret_arn" {
  description = "ARN of RabbitMQ credentials secret"
  value       = aws_secretsmanager_secret.rabbitmq.arn
}

output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "namespace_name" {
  description = "Name of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "data_services_security_group_id" {
  description = "ID of the data services security group"
  value       = aws_security_group.data_services.id
}
