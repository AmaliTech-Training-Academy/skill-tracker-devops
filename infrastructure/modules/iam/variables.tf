variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that ECS tasks need access to"
  type        = list(string)
  default     = ["*"]
}

variable "rds_secret_arns" {
  description = "List of RDS secret ARNs in Secrets Manager"
  type        = list(string)
  default     = ["*"]
}

variable "enable_xray" {
  description = "Enable AWS X-Ray for distributed tracing"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
