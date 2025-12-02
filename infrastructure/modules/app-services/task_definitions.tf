# Discovery Server Task Definition (starts first)
resource "aws_ecs_task_definition" "discovery_server" {
  family                   = "${var.project_name}-${var.environment}-discovery-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode(concat([
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
  ], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-discovery'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8082']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

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

  container_definitions = jsonencode(concat([
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
  ], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-config'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8081']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

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

  container_definitions = jsonencode(concat([
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

      secrets = [
        {
          name      = "JWT_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:JWT_SECRET::"
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
  ], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-gateway'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8080']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

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

  container_definitions = jsonencode(concat([
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
          name  = "COOKIE_SECURE"
          value = "true"
        },
        {
          name  = "BASE_URL"
          value = "https://d32qfw4cukmoa9.cloudfront.net"
        },
        {
          name  = "FRONTEND_URL"
          value = "https://dev.dy006p1vkpl2e.amplifyapp.com"
        },
        {
          name  = "GOOGLE_REDIRECT_URI"
          value = "https://d32qfw4cukmoa9.cloudfront.net/login/oauth2/code/google"
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
          value = "https://d32qfw4cukmoa9.cloudfront.net/login/oauth2/code/github"
        },
        {
          name  = "GITHUB_CLIENT_AUTHENTICATION_METHOD"
          value = "client_secret_post"
        },
        {
          name  = "SPRING_RABBITMQ_HOST"
          value = "rabbitmq.${var.service_discovery_namespace}"
        },
        {
          name  = "SPRING_RABBITMQ_PORT"
          value = "5672"
        },
        {
          name  = "LOGIN_URL"
          value = "https://dev.dy006p1vkpl2e.amplifyapp.com/login"
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
        },
        {
          name      = "GOOGLE_CLIENT_ID"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-app-secrets-oauth-google-vZ0PBA:GOOGLE_CLIENT_ID::"
        },
        {
          name      = "GOOGLE_CLIENT_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-app-secrets-oauth-google-vZ0PBA:GOOGLE_CLIENT_SECRET::"
        },
        {
          name      = "GITHUB_CLIENT_ID"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-app-secrets-oauth-github-7gDyXh:GITHUB_CLIENT_ID::"
        },
        {
          name      = "GITHUB_CLIENT_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-app-secrets-oauth-github-7gDyXh:GITHUB_CLIENT_SECRET::"
        },
        {
          name      = "RABBITMQ_USER"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:username::"
        },
        {
          name      = "RABBITMQ_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:password::"
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
  ], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-user'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8084']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

  tags = var.tags
}


# Task Service Task Definition (starts after config server)
resource "aws_ecs_task_definition" "task_service" {
  family                   = "${var.project_name}-${var.environment}-task-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode(concat([
    {
      name      = "task-service"
      image     = "${var.ecr_repository_urls["task-service"]}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8085
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
          name  = "SERVER_PORT"
          value = "8085"
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
          value = "task-service.${var.service_discovery_namespace}"
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
          name  = "SPRING_RABBITMQ_HOST"
          value = "rabbitmq.${var.service_discovery_namespace}"
        },
        {
          name  = "SPRING_RABBITMQ_PORT"
          value = "5672"
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
          name      = "RABBITMQ_USER"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:username::"
        },
        {
          name      = "RABBITMQ_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:password::"
        },
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-google-api-key-9hinUM:OPENAI_API_KEY::"
        }
        
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["task-service"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "task-service"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "nc -z localhost 8085 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-task'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8085']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

  tags = var.tags
}


# Analytics Service Task Definition (starts after config server)
resource "aws_ecs_task_definition" "analytics_service" {
  family                   = "${var.project_name}-${var.environment}-analytics-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode(concat([
    {
      name      = "analytics-service"
      image     = "${var.ecr_repository_urls["analytics-service"]}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8086
          protocol      = "tcp"
        }
      ]

      environment = [
        {
name="ANALYTICS_SCORE_LOW_RUBRIC_THRESHOLD",value="40",
        },
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
          name  = "SERVER_PORT"
          value = "8086"
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
          value = "analytics-service.${var.service_discovery_namespace}"
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
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://${split(":", var.rds_endpoint)[0]}:5432/${var.rds_db_name}"
        },
        {
          name  = "SPRING_JPA_HIBERNATE_DDL_AUTO"
          value = "update"
        },
        {
          name  = "SPRING_DATA_MONGODB_HOST"
          value = "mongodb.${var.service_discovery_namespace}"
        },
        {
          name  = "SPRING_DATA_MONGODB_PORT"
          value = "27017"
        },
        {
          name  = "SPRING_DATA_MONGODB_DATABASE"
          value = "analytics_db"
        },
        {
          name  = "SPRING_RABBITMQ_HOST"
          value = "rabbitmq.${var.service_discovery_namespace}"
        },
        {
          name  = "SPRING_RABBITMQ_PORT"
          value = "5672"
        },
        {
          name  = "RABBITMQ_HOST"
          value = "rabbitmq.${var.service_discovery_namespace}"
        },
        {
          name  = "RABBITMQ_STOMP_PORT"
          value = "61613"
        },
        {
          name  = "SPRING_DATA_REDIS_HOST"
          value = "redis.${var.service_discovery_namespace}"
        },
        {
          name  = "SPRING_DATA_REDIS_PORT"
          value = "6379"
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
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = "${var.rds_secret_arn}:username::"
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "${var.rds_secret_arn}:password::"
        },
        {
          name      = "SPRING_DATA_MONGODB_USERNAME"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-mongodb-credentials-7gkK4n:username::"
        },
        {
          name      = "SPRING_DATA_MONGODB_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-mongodb-credentials-7gkK4n:password::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:${var.project_name}-${var.environment}-app-secrets-jwt:JWT_SECRET::"
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
          name      = "RABBITMQ_USER"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:username::"
        },
        {
          name      = "RABBITMQ_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["analytics-service"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "analytics-service"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "nc -z localhost 8086 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-analytics'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8086']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

  tags = var.tags
}


# Feedback Service Task Definition
resource "aws_ecs_task_definition" "feedback_service" {
  family                   = "${var.project_name}-${var.environment}-feedback-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode(concat([{
    name      = "feedback-service"
    image     = "${var.ecr_repository_urls["feedback-service"]}:latest"
    essential = true
    
    portMappings = [{
      containerPort = 8090
      protocol      = "tcp"
    }]

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
        name  = "SERVER_PORT"
        value = "8090"
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
        value = "feedback-service.${var.service_discovery_namespace}"
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
        name  = "SPRING_RABBITMQ_HOST"
        value = "rabbitmq.${var.service_discovery_namespace}"
      },
      {
        name  = "SPRING_RABBITMQ_PORT"
        value = "5672"
      }
    ]

    secrets = [
      {
        name      = "OPENAI_API_KEY"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-google-api-key-9hinUM:OPENAI_API_KEY::"
      },
      {
        name      = "POSTGRES_USER"
        valueFrom = "${var.rds_secret_arn}:username::"
      },
      {
        name      = "POSTGRES_PASSWORD"
        valueFrom = "${var.rds_secret_arn}:password::"
      },
      {
        name      = "RABBITMQ_USER"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:username::"
      },
      {
        name      = "RABBITMQ_PASSWORD"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:password::"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_groups["feedback-service"]
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "feedback-service"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "nc -z localhost 8090 || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 120
    }
  }], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-feedback'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8090']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

  tags = var.tags
}

# Notification Service Task Definition
resource "aws_ecs_task_definition" "notification_service" {
  family                   = "${var.project_name}-${var.environment}-notification-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode(concat([{
    name      = "notification-service"
    image     = "${var.ecr_repository_urls["notification-service"]}:latest"
    essential = true
    
    portMappings = [{
      containerPort = 8091
      protocol      = "tcp"
    }]

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
        name  = "SERVER_PORT"
        value = "8091"
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
        value = "notification-service.${var.service_discovery_namespace}"
      },
      {
        name  = "SPRING_RABBITMQ_HOST"
        value = "rabbitmq.${var.service_discovery_namespace}"
      },
      {
        name  = "SPRING_RABBITMQ_PORT"
        value = "5672"
      },
      {
        name  = "SPRING_DATA_MONGODB_HOST"
        value = "mongodb.${var.service_discovery_namespace}"
      },
      {
        name  = "SPRING_DATA_MONGODB_PORT"
        value = "27017"
      },
      {
        name  = "SPRING_DATA_MONGODB_DATABASE"
        value = "notification_db"
      }
    ]

    secrets = [
      {
        name      = "RABBITMQ_USER"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:username::"
      },
      {
        name      = "RABBITMQ_PASSWORD"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-rabbitmq-credentials-KgtgXp:password::"
      },
      {
        name      = "SPRING_DATA_MONGODB_USERNAME"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-mongodb-credentials-7gkK4n:username::"
      },
      {
        name      = "SPRING_DATA_MONGODB_PASSWORD"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-mongodb-credentials-7gkK4n:password::"
      },
      {
        name      = "MONGO_USER"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-mongodb-credentials-7gkK4n:username::"
      },
      {
        name      = "MONGO_PASSWORD"
        valueFrom = "arn:aws:secretsmanager:${var.aws_region}:962496666337:secret:sdt-dev-mongodb-credentials-7gkK4n:password::"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_groups["notification-service"]
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "notification-service"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "nc -z localhost 8091 || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 120
    }
  }], var.enable_adot_sidecar ? [
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      portMappings = [
        {
          containerPort = var.adot_exporter_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_OTEL_LOG_LEVEL", value = "INFO" },
        { name = "AOT_CONFIG_CONTENT", value = <<-EOT
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-notification'
          metrics_path: /actuator/prometheus
          static_configs:
            - targets: ['localhost:8091']
exporters:
  prometheus:
    endpoint: 0.0.0.0:${var.adot_exporter_port}
service:
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheus]
EOT
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_groups["cluster"]
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ] : []))

  tags = var.tags
}
