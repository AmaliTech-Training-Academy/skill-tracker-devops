locals {
  tg_enabled = var.target_group_arn != null && var.target_group_arn != ""
}

resource "aws_ecs_service" "service" {
  for_each = { for s in var.services : s.name => s }

  name            = "${var.project_name}-${var.environment}-${each.key}"
  cluster         = var.cluster_id
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.service[each.key].arn

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = (local.tg_enabled && each.key == "api-gateway") ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  enable_execute_command = true

  lifecycle {
    ignore_changes = [task_definition]
  }
}
