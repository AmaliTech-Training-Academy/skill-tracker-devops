output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "ecs_dashboard_name" {
  description = "Name of the ECS CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.ecs.dashboard_name
}

output "rds_dashboard_name" {
  description = "Name of the RDS CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.rds.dashboard_name
}

output "vpc_flow_logs_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch log group"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "vpc_flow_logs_group_arn" {
  description = "ARN of the VPC Flow Logs CloudWatch log group"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : null
}

output "alarm_arns" {
  description = "Map of alarm ARNs"
  value = {
    ecs_cpu_high           = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
    ecs_memory_high        = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
    rds_cpu_high           = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
    rds_storage_low        = aws_cloudwatch_metric_alarm.rds_storage_low.arn
    rds_connections_high   = aws_cloudwatch_metric_alarm.rds_connections_high.arn
  }
}
