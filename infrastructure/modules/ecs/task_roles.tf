# This file can be used to define service-specific task roles if needed
# For now, we'll use the common ECS task roles from the IAM module

# Auto-scaling Target for ECS Services
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = var.services

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_cluster.main]
}

# Auto-scaling Policy - CPU Based
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  for_each = var.services

  name               = "${var.project_name}-${var.environment}-${each.key}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = each.value.cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto-scaling Policy - Memory Based
resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  for_each = var.services

  name               = "${var.project_name}-${var.environment}-${each.key}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = each.value.memory_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
