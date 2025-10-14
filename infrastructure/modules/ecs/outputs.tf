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

# ECR Repository URLs
output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value = {
    auth_service       = aws_ecr_repository.auth_service.repository_url
    content_service    = aws_ecr_repository.content_service.repository_url
    submission_service = aws_ecr_repository.submission_service.repository_url
    sandbox_runner     = aws_ecr_repository.sandbox_runner.repository_url
  }
}

# ECR Repository ARNs
output "ecr_repository_arns" {
  description = "Map of ECR repository ARNs"
  value = {
    auth_service       = aws_ecr_repository.auth_service.arn
    content_service    = aws_ecr_repository.content_service.arn
    submission_service = aws_ecr_repository.submission_service.arn
    sandbox_runner     = aws_ecr_repository.sandbox_runner.arn
  }
}

# CloudWatch Log Groups
output "log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    auth_service       = aws_cloudwatch_log_group.auth_service.name
    content_service    = aws_cloudwatch_log_group.content_service.name
    submission_service = aws_cloudwatch_log_group.submission_service.name
    sandbox_runner     = aws_cloudwatch_log_group.sandbox_runner.name
    cluster            = aws_cloudwatch_log_group.cluster.name
  }
}

output "log_group_arns" {
  description = "Map of CloudWatch log group ARNs"
  value = {
    auth_service       = aws_cloudwatch_log_group.auth_service.arn
    content_service    = aws_cloudwatch_log_group.content_service.arn
    submission_service = aws_cloudwatch_log_group.submission_service.arn
    sandbox_runner     = aws_cloudwatch_log_group.sandbox_runner.arn
    cluster            = aws_cloudwatch_log_group.cluster.arn
  }
}
