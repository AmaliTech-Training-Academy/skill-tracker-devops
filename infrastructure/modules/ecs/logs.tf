# CloudWatch Log Group for Auth Service
resource "aws_cloudwatch_log_group" "auth_service" {
  name              = "/ecs/${var.project_name}/${var.environment}/auth-service"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = "auth-service"
    }
  )
}

# CloudWatch Log Group for Content Service
resource "aws_cloudwatch_log_group" "content_service" {
  name              = "/ecs/${var.project_name}/${var.environment}/content-service"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = "content-service"
    }
  )
}

# CloudWatch Log Group for Submission Service
resource "aws_cloudwatch_log_group" "submission_service" {
  name              = "/ecs/${var.project_name}/${var.environment}/submission-service"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = "submission-service"
    }
  )
}

# CloudWatch Log Group for Sandbox Runner
resource "aws_cloudwatch_log_group" "sandbox_runner" {
  name              = "/ecs/${var.project_name}/${var.environment}/sandbox-runner"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = "sandbox-runner"
    }
  )
}

# CloudWatch Log Group for ECS Cluster
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/ecs/${var.project_name}/${var.environment}/cluster"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
