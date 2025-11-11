output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.create_alb ? aws_security_group.alb[0].id : null
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.main[0].arn : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.main[0].dns_name : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.create_alb ? aws_lb_target_group.main[0].arn : null
}

output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = var.create_alb ? aws_lb_listener.http[0].arn : null
}

# ECR Repository URLs
output "ecr_repository_urls" {
  description = "Map of ECR repository URLs for all services"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

# ECR Repository ARNs
output "ecr_repository_arns" {
  description = "Map of ECR repository ARNs for all services"
  value       = { for k, v in aws_ecr_repository.services : k => v.arn }
}

# CloudWatch Log Groups
output "log_groups" {
  description = "Map of CloudWatch log group names for all services"
  value = merge(
    { for k, v in aws_cloudwatch_log_group.services : k => v.name },
    { cluster = aws_cloudwatch_log_group.cluster.name }
  )
}

output "log_group_arns" {
  description = "Map of CloudWatch log group ARNs for all services"
  value = merge(
    { for k, v in aws_cloudwatch_log_group.services : k => v.arn },
    { cluster = aws_cloudwatch_log_group.cluster.arn }
  )
}
