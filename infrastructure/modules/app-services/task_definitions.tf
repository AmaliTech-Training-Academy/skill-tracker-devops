# Discovery Server Task Definition (starts first)
resource "aws_ecs_task_definition" "discovery_server" {
  family                   = "${var.project_name}-${var.environment}-discovery-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
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
          value = "localhost"
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
        command     = ["CMD-SHELL", "nc -z localhost 8082 || exit 1"]
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
  cpu                      = "512"
  memory                   = "1024"
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
          name  = "SPRING_CLOUD_CONFIG_SERVER_GIT_URI"
          value = "https://github.com/${var.config_repo}"
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
        command     = ["CMD-SHELL", "nc -z localhost 8081 || exit 1"]
        interval    = 60
        timeout     = 10
        retries     = 5
        startPeriod = 180
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
        command     = ["CMD-SHELL", "nc -z localhost 8080 || exit 1"]
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
        },
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "dev"
        },
        {
          name  = "EUREKA_INSTANCE_PREFER_IP_ADDRESS"
          value = "false"
        },
        {
          name  = "EUREKA_INSTANCE_HOSTNAME"
          value = "user-service.${var.service_discovery_namespace}"
        },
        {
          name  = "POSTGRES_HOST"
          value = split(":", var.rds_endpoint)[0]
        },
        {
          name  = "POSTGRES_DB"
          value = var.rds_db_name
        },
        {
          name  = "SPRING_JPA_HIBERNATE_DDL_AUTO"
          value = "update"
        },
        {
          name  = "SPRING_DATA_REDIS_HOST"
          value = "redis.${var.service_discovery_namespace}"
        },
        {
          name  = "SPRING_DATA_REDIS_PORT"
          value = "6379"
        },
        {
          name  = "COOKIE_DOMAIN"
          value = "localhost"
        },
        {
          name  = "COOKIE_SECURE"
          value = "false"
        },
        {
          name  = "BASE_URL"
          value = "https://lmmqcw9520.execute-api.eu-west-1.amazonaws.com/dev"
        },
        {
          name  = "FRONTEND_URL"
          value = "https://dev.dy006p1vkpl2e.amplifyapp.com"
        },
        {
          name  = "GOOGLE_CLIENT_ID"
          value = "71818883519-qruu2n5l2qtb75t2s50gbulj5qj5uuap.apps.googleusercontent.com"
        },
        {
          name  = "GOOGLE_CLIENT_SECRET"
          value = "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"
        },
        {
          name  = "GOOGLE_REDIRECT_URI"
          value = "https://lmmqcw9520.execute-api.eu-west-1.amazonaws.com/dev/login/oauth2/code/google"
        },
        {
          name  = "GOOGLE_AUTHORIZATION_URI"
          value = "https://accounts.google.com/o/oauth2/v2/auth"
        },
        {
          name  = "GOOGLE_TOKEN_URI"
          value = "https://www.googleapis.com/oauth2/v4/token"
        },
        {
          name  = "GOOGLE_USER_INFO_URI"
          value = "https://www.googleapis.com/oauth2/v3/userinfo"
        },
        {
          name  = "GITHUB_CLIENT_ID"
          value = "github-client-id"
        },
        {
          name  = "GITHUB_CLIENT_SECRET"
          value = "github-client-secret"
        },
        {
          name  = "GITHUB_AUTHORIZATION_URI"
          value = "https://github.com/login/oauth/authorize"
        },
        {
          name  = "GITHUB_TOKEN_URI"
          value = "https://github.com/login/oauth/access_token"
        },
        {
          name  = "GITHUB_USER_INFO_URI"
          value = "https://api.github.com/user"
        },
        {
          name  = "GITHUB_USER_NAME_ATTRIBUTE"
          value = "login"
        },
        {
          name  = "GITHUB_REDIRECT_URI"
          value = "https://lmmqcw9520.execute-api.eu-west-1.amazonaws.com/dev/login/oauth2/code/github"
        },
        {
          name  = "GITHUB_CLIENT_AUTHENTICATION_METHOD"
          value = "client_secret_post"
        }
      ]

      secrets = [
        {
          name      = "POSTGRES_USER"
          valueFrom = "${var.rds_secret_arn}:username::"
        },
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${var.rds_secret_arn}:password::"
        },
        {
          name      = "SENDGRID_API_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-sendgrid-credentials-gvRTix:api_key::"
        },
        {
          name      = "MAIL_USERNAME"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-sendgrid-credentials-gvRTix:from_email::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:JWT_SECRET::"
        },
        {
          name      = "HMAC_SECRET_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:HMAC_SECRET_KEY::"
        },
        {
          name      = "HMAC_ALGORITHM"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:HMAC_ALGORITHM::"
        },
        {
          name      = "JWT_EXPIRATION"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:JWT_EXPIRATION::"
        },
        {
          name      = "JWT_ACCESS_EXPIRATION"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:JWT_ACCESS_EXPIRATION::"
        },
        {
          name      = "JWT_REFRESH_EXPIRATION"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:JWT_REFRESH_EXPIRATION::"
        },
        {
          name      = "RESET_TOKEN_EXPIRATION"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:RESET_TOKEN_EXPIRATION::"
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
        command     = ["CMD-SHELL", "nc -z localhost 8084 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = var.tags
}