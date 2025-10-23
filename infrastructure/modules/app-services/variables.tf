variable "project_name" { type = string }
variable "environment"  { type = string }

variable "cluster_id"   { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }

variable "task_role_arn" {
  description = "IAM role ARN assumed by the task (application permissions)"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN used by the ECS agent to pull images and publish logs"
  type        = string
}

variable "target_group_arn" { type = string } # For api-gateway only; can be null

variable "log_groups" {
  description = "Map of log group names keyed by service name"
  type        = map(string)
}

variable "services" {
  description = "List of services to create"
  type = list(object({
    name          = string
    port          = number
    desired_count = number
    cpu           = number
    memory        = number
  }))
}
