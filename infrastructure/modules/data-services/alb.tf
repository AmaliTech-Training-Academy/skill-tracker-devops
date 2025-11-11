# Target Group for RabbitMQ Management UI
resource "aws_lb_target_group" "rabbitmq_mgmt" {
  name        = "${var.project_name}-${var.environment}-rabbitmq-mgmt"
  port        = 15672
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "15672"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  tags = var.tags
}

# ALB Listener Rule for RabbitMQ Management UI (host header based)
resource "aws_lb_listener_rule" "rabbitmq_mgmt" {
  listener_arn = var.alb_listener_arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_mgmt.arn
  }

  condition {
    host_header {
      values = ["rabbitmq.*"]
    }
  }

  tags = var.tags
}

# Update RabbitMQ ECS Service to use ALB
resource "aws_ecs_service" "rabbitmq_with_alb" {
  count           = 0  # Disabled, will update main service instead
  name            = "${var.project_name}-${var.environment}-rabbitmq"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.rabbitmq.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.data_services.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rabbitmq_mgmt.arn
    container_name   = "rabbitmq"
    container_port   = 15672
  }

  enable_execute_command = true

  service_registries {
    registry_arn = aws_service_discovery_service.rabbitmq.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rabbitmq-service"
    }
  )
}
