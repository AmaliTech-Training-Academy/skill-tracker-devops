output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.ecs.ecr_repository_urls
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_secret_arn" {
  description = "ARN of the RDS credentials secret"
  value       = module.rds.secrets_manager_secret_arn
}

output "s3_buckets" {
  description = "Map of S3 bucket names"
  value = {
    user_uploads  = module.s3.user_uploads_bucket_id
    static_assets = module.s3.static_assets_bucket_id
    app_logs      = module.s3.app_logs_bucket_id
  }
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.api_gateway_url
}

output "amplify_app_url" {
  description = "URL of the Amplify app"
  value       = module.amplify.app_url
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value       = module.ecs.log_groups
}

output "monitoring_dashboards" {
  description = "CloudWatch dashboard names"
  value = {
    ecs = module.monitoring.ecs_dashboard_name
    rds = module.monitoring.rds_dashboard_name
  }
}
