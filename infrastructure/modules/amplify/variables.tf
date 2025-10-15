variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "repository_url" {
  description = "URL of the Git repository (GitHub, GitLab, etc.)"
  type        = string
}

variable "main_branch_name" {
  description = "Name of the main branch to deploy"
  type        = string
  default     = "main"
}

variable "framework" {
  description = "Frontend framework (e.g., Angular, React, Next.js, Vue)"
  type        = string
  default     = "Angular"
}

variable "platform" {
  description = "Platform type (WEB or WEB_COMPUTE for SSR)"
  type        = string
  default     = "WEB"
}

variable "build_spec" {
  description = "Custom build specification (YAML format)"
  type        = string
  default     = ""
}

variable "build_output_directory" {
  description = "Build output directory"
  type        = string
  default     = "dist/angular-app"
}

variable "environment_variables" {
  description = "Environment variables for the Amplify app"
  type        = map(string)
  default     = {}
}

variable "branch_environment_variables" {
  description = "Environment variables for the specific branch"
  type        = map(string)
  default     = {}
}

variable "enable_auto_branch_creation" {
  description = "Enable automatic branch creation"
  type        = bool
  default     = false
}

variable "enable_branch_auto_build" {
  description = "Enable automatic builds for branches"
  type        = bool
  default     = true
}

variable "enable_branch_auto_deletion" {
  description = "Enable automatic deletion of branches"
  type        = bool
  default     = true
}

variable "auto_branch_creation_patterns" {
  description = "Patterns for automatic branch creation"
  type        = list(string)
  default     = ["feature/*", "dev/*"]
}

variable "custom_rules" {
  description = "Custom redirect and rewrite rules"
  type = list(object({
    source = string
    status = string
    target = string
  }))
  default = [
    {
      source = "/**"
      status = "404-200"
      target = "/index.html"
    }
  ]
}

variable "github_access_token" {
  description = "GitHub access token for private repositories"
  type        = string
  default     = ""
  sensitive   = true
}

variable "iam_service_role_arn" {
  description = "IAM service role ARN for Amplify"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Custom domain name for the app"
  type        = string
  default     = ""
}

variable "create_webhook" {
  description = "Create a webhook for manual deployments"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
