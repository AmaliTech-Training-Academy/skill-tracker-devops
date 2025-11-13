variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_log_group" {
  description = "CloudWatch log group for ECS"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
  default     = null
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
  default     = null
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}

variable "alarm_email_endpoints" {
  description = "List of email addresses to receive alarm notifications"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# New variables for S3 log export
variable "enable_log_export_to_s3" {
  description = "Enable automatic export of CloudWatch logs to S3"
  type        = bool
  default     = false
}

variable "app_logs_bucket_id" {
  description = "S3 bucket ID for application logs"
  type        = string
  default     = ""
}

variable "app_logs_bucket_arn" {
  description = "S3 bucket ARN for application logs"
  type        = string
  default     = ""
}

variable "service_names" {
  description = "List of service names for log export"
  type        = list(string)
  default     = [
    "config-server",
    "discovery-server", 
    "api-gateway",
    "bff-service",
    "user-service",
    "task-service",
    "analytics-service",
    "payment-service",
    "gamification-service",
    "practice-service",
    "feedback-service",
    "notification-service",
    "mongodb",
    "redis",
    "rabbitmq"
  ]
}

