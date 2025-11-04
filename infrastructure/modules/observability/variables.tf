variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where monitoring instance will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for monitoring instance"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name to monitor"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for monitoring"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "prometheus_volume_size" {
  description = "Prometheus data volume size in GB"
  type        = number
  default     = 50
}

variable "prometheus_version" {
  description = "Prometheus version to install"
  type        = string
  default     = "2.48.0"
}

variable "grafana_version" {
  description = "Grafana Docker image version"
  type        = string
  default     = "10.2.2"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Grafana and Prometheus web UIs"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}

variable "create_elastic_ip" {
  description = "Whether to create an Elastic IP for the monitoring instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
