output "file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.data.id
}

output "file_system_arn" {
  description = "ARN of the EFS file system"
  value       = aws_efs_file_system.data.arn
}

output "file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.data.dns_name
}

output "mongodb_access_point_id" {
  description = "ID of the MongoDB EFS access point"
  value       = aws_efs_access_point.mongodb.id
}

output "mongodb_access_point_arn" {
  description = "ARN of the MongoDB EFS access point"
  value       = aws_efs_access_point.mongodb.arn
}

output "redis_access_point_id" {
  description = "ID of the Redis EFS access point"
  value       = aws_efs_access_point.redis.id
}

output "redis_access_point_arn" {
  description = "ARN of the Redis EFS access point"
  value       = aws_efs_access_point.redis.arn
}

output "rabbitmq_access_point_id" {
  description = "ID of the RabbitMQ EFS access point"
  value       = aws_efs_access_point.rabbitmq.id
}

output "rabbitmq_access_point_arn" {
  description = "ARN of the RabbitMQ EFS access point"
  value       = aws_efs_access_point.rabbitmq.arn
}

output "efs_security_group_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs.id
}
