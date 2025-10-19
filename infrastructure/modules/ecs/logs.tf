# CloudWatch Log Groups - Dynamic creation for all services
resource "aws_cloudwatch_log_group" "services" {
  for_each = var.services

  name              = "/ecs/${var.project_name}/${var.environment}/${each.key}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = each.key
    }
  )
}

# CloudWatch Log Group for ECS Cluster
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/ecs/${var.project_name}/${var.environment}/cluster"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
