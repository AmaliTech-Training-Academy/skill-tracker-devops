# Discovery Server Service (starts first)
resource "aws_ecs_service" "discovery_server" {
  name            = "${var.project_name}-${var.environment}-discovery-server"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.discovery_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.discovery_server.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-discovery-server-service"
  })
}

# Config Server Service (starts after discovery server is healthy)
resource "aws_ecs_service" "config_server" {
  name            = "${var.project_name}-${var.environment}-config-server"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.config_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.config_server.arn
  }

  depends_on = [aws_ecs_service.discovery_server]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-config-server-service"
  })
}

# API Gateway Service (starts after config server)
resource "aws_ecs_service" "api_gateway" {
  name            = "${var.project_name}-${var.environment}-api-gateway"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "api-gateway"
    container_port   = 8080
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api_gateway.arn
  }

  depends_on = [aws_ecs_service.config_server]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api-gateway-service"
  })
}

# User Service (starts after config server)
resource "aws_ecs_service" "user_service" {
  name            = "${var.project_name}-${var.environment}-user-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.user_service.arn
  }

  depends_on = [aws_ecs_service.config_server]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-user-service-service"
  })
}

# Service Discovery Services
resource "aws_service_discovery_service" "discovery_server" {
  name = "discovery-server"

  dns_config {
    namespace_id = var.service_discovery_namespace_id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # health_check_grace_period_seconds = 30
}

resource "aws_service_discovery_service" "config_server" {
  name = "config-server"

  dns_config {
    namespace_id = var.service_discovery_namespace_id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # health_check_grace_period_seconds = 60
}

resource "aws_service_discovery_service" "api_gateway" {
  name = "api-gateway"

  dns_config {
    namespace_id = var.service_discovery_namespace_id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # health_check_grace_period_seconds = 90
}

resource "aws_service_discovery_service" "user_service" {
  name = "user-service"

  dns_config {
    namespace_id = var.service_discovery_namespace_id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # health_check_grace_period_seconds = 120
}