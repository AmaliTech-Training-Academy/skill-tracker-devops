variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecs_cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS security group ID"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "ecr_repository_urls" {
  description = "ECR repository URLs"
  type        = map(string)
}

variable "log_groups" {
  description = "CloudWatch log groups"
  type        = map(string)
}

variable "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  type        = string
}

variable "service_discovery_namespace" {
  description = "Service discovery namespace name"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "config_repo" {
  description = "Git repository for configuration"
  type        = string
  default     = "AmaliTech-Training-Academy/skill-tracker-configs"
}

variable "rds_endpoint" {
  description = "RDS endpoint"
  type        = string
  default     = ""
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = ""
}

variable "rds_secret_arn" {
  description = "RDS credentials secret ARN"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_adot_sidecar" {
  description = "Enable AWS Distro for OpenTelemetry (ADOT) sidecar in task definitions"
  type        = bool
  default     = false
}

variable "adot_exporter_port" {
  description = "Port exposed by ADOT prometheus exporter for Prometheus scraping"
  type        = number
  default     = 8889
}

variable "monitoring_security_group_id" {
  description = "Security group ID of the monitoring host (Prometheus) allowed to scrape ADOT exporter"
  type        = string
  default     = null
}