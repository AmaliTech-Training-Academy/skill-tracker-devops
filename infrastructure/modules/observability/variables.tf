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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for monitoring host"
  type        = string
  default     = "t3.small"
}

variable "service_discovery_namespace" {
  description = "Service discovery namespace (e.g., dev.sdt.local)"
  type        = string
}

variable "adot_exporter_port" {
  description = "Port exposed by ADOT exporters"
  type        = number
  default     = 8889
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to monitoring instance"
  type        = list(string)
  default     = []
}

variable "web_allowed_cidrs" {
  description = "CIDR blocks allowed to access Prometheus/Grafana web UIs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
