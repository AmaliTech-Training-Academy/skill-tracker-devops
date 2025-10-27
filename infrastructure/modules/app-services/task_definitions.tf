# Discovery Server Task Definition (starts first)
resource "aws_ecs_task_definition" "discovery_server" {
  family                   = "${var.project_name}-${var.environment}-discovery-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "discovery-server"
      image     = "${var.ecr_repository_urls["discovery-server"]}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8082
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DISCOVERY_HOST"
          value = "discovery-server.${var.service_discovery_namespace}"
        },
        {
          name  = "DISCOVERY_PORT"
          value = "8082"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["discovery-server"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "discovery-server"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8082/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

# Config Server Task Definition (starts after discovery)
resource "aws_ecs_task_definition" "config_server" {
  family                   = "${var.project_name}-${var.environment}-config-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "config-server"
      image     = "${var.ecr_repository_urls["config-server"]}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8081
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "CONFIG_REPO"
          value = var.config_repo
        },
        {
          name  = "DISCOVERY_HOST"
          value = "discovery-server.${var.service_discovery_namespace}"
        },
        {
          name  = "DISCOVERY_PORT"
          value = "8082"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["config-server"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "config-server"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8081/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

# API Gateway Task Definition (starts after config server)
resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "${var.project_name}-${var.environment}-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "api-gateway"
      image     = "${var.ecr_repository_urls["api-gateway"]}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "CONFIG_HOST"
          value = "config-server.${var.service_discovery_namespace}"
        },
        {
          name  = "CONFIG_PORT"
          value = "8081"
        },
        {
          name  = "DISCOVERY_HOST"
          value = "discovery-server.${var.service_discovery_namespace}"
        },
        {
          name  = "DISCOVERY_PORT"
          value = "8082"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["api-gateway"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api-gateway"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 90
      }
    }
  ])

  tags = var.tags
}

# User Service Task Definition (starts after config server)
resource "aws_ecs_task_definition" "user_service" {
  family                   = "${var.project_name}-${var.environment}-user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "user-service"
      image     = "${var.ecr_repository_urls["user-service"]}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8084
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "CONFIG_HOST"
          value = "config-server.${var.service_discovery_namespace}"
        },
        {
          name  = "CONFIG_PORT"
          value = "8081"
        },
        {
          name  = "DISCOVERY_HOST"
          value = "discovery-server.${var.service_discovery_namespace}"
        },
        {
          name  = "DISCOVERY_PORT"
          value = "8082"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["user-service"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "user-service"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8084/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = var.tags
}