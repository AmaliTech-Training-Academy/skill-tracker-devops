variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS tasks"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "efs_file_system_id" {
  description = "ID of the EFS file system"
  type        = string
}

variable "mongodb_access_point_id" {
  description = "ID of the MongoDB EFS access point"
  type        = string
}

variable "redis_access_point_id" {
  description = "ID of the Redis EFS access point"
  type        = string
}

variable "rabbitmq_access_point_id" {
  description = "ID of the RabbitMQ EFS access point"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key for AI-powered features"
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_api_key" {
  description = "Google API key for MCQ generation"
  type        = string
  sensitive   = true
  default     = ""
}
