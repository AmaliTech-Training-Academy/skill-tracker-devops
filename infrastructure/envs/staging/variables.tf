variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "enable_xray" {
  description = "Enable AWS X-Ray for distributed tracing"
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Port on which containers listen"
  type        = number
  default     = 8080
}

variable "db_name" {
  description = "Name of the default database"
  type        = string
  default     = "sdt_staging"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "sdt_admin"
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["https://staging.yourdomain.com"]
}

variable "alarm_email_endpoints" {
  description = "List of email addresses to receive alarm notifications"
  type        = list(string)
  default     = []
}

variable "amplify_repository_url" {
  description = "URL of the Git repository for Amplify"
  type        = string
  default     = "https://github.com/your-org/sdt-frontend"
}

variable "github_access_token" {
  description = "GitHub access token for private repositories"
  type        = string
  default     = ""
  sensitive   = true
}
