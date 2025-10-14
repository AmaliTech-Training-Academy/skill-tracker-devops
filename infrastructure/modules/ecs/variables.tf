variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "container_port" {
  description = "Port on which containers listen"
  type        = number
  default     = 8080
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}

variable "create_alb" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
}

variable "services" {
  description = "Map of services with auto-scaling configuration"
  type = map(object({
    min_capacity         = number
    max_capacity         = number
    cpu_target_value     = number
    memory_target_value  = number
  }))
  default = {
    auth-service = {
      min_capacity        = 1
      max_capacity        = 4
      cpu_target_value    = 70
      memory_target_value = 80
    }
    content-service = {
      min_capacity        = 1
      max_capacity        = 4
      cpu_target_value    = 70
      memory_target_value = 80
    }
    submission-service = {
      min_capacity        = 1
      max_capacity        = 4
      cpu_target_value    = 70
      memory_target_value = 80
    }
    sandbox-runner = {
      min_capacity        = 1
      max_capacity        = 6
      cpu_target_value    = 70
      memory_target_value = 80
    }
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
