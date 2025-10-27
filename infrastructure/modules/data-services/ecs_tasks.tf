# ECS Task Definition for MongoDB
resource "aws_ecs_task_definition" "mongodb" {
  family                   = "${var.project_name}-${var.environment}-mongodb"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "mongodb"
      image     = "mongo:7"
      essential = true

      portMappings = [
        {
          containerPort = 27017
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "MONGO_INITDB_DATABASE"
          value = "audit_db"
        }
      ]

      secrets = [
        {
          name      = "MONGO_INITDB_ROOT_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.mongodb.arn}:username::"
        },
        {
          name      = "MONGO_INITDB_ROOT_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.mongodb.arn}:password::"
        }
      ]

      command = ["--auth"]

      mountPoints = [
        {
          sourceVolume  = "mongodb-data"
          containerPath = "/data/db"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.mongodb.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "mongodb"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "mongosh --eval 'db.adminCommand(\"ping\")' || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "mongodb-data"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      
      authorization_config {
        access_point_id = var.mongodb_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mongodb"
    }
  )
}

# ECS Service for MongoDB
resource "aws_ecs_service" "mongodb" {
  name            = "${var.project_name}-${var.environment}-mongodb"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.mongodb.arn
  desired_count   = 0  # Disabled - not used by any deployed services
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.data_services.id]
  }

  enable_execute_command = true

  service_registries {
    registry_arn = aws_service_discovery_service.mongodb.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mongodb-service"
    }
  )
}

# ECS Task Definition for Redis
resource "aws_ecs_task_definition" "redis" {
  family                   = "${var.project_name}-${var.environment}-redis"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "redis:7-alpine"
      essential = true

      portMappings = [
        {
          containerPort = 6379
          protocol      = "tcp"
        }
      ]

      command = ["redis-server", "--appendonly", "yes"]

      mountPoints = [
        {
          sourceVolume  = "redis-data"
          containerPath = "/data"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.redis.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "redis"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "redis-cli ping || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  volume {
    name = "redis-data"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      
      authorization_config {
        access_point_id = var.redis_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis"
    }
  )
}

# ECS Service for Redis
resource "aws_ecs_service" "redis" {
  name            = "${var.project_name}-${var.environment}-redis"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 0  # Disabled - only needed when task-service/user-service are deployed
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.data_services.id]
  }

  enable_execute_command = true

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-service"
    }
  )
}

# ECS Task Definition for RabbitMQ
resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "${var.project_name}-${var.environment}-rabbitmq"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "rabbitmq"
      image     = "rabbitmq:3-management-alpine"
      essential = true

      portMappings = [
        {
          containerPort = 5672
          protocol      = "tcp"
        },
        {
          containerPort = 15672
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "RABBITMQ_DEFAULT_USER"
          valueFrom = "${aws_secretsmanager_secret.rabbitmq.arn}:username::"
        },
        {
          name      = "RABBITMQ_DEFAULT_PASS"
          valueFrom = "${aws_secretsmanager_secret.rabbitmq.arn}:password::"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "rabbitmq-data"
          containerPath = "/var/lib/rabbitmq"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.rabbitmq.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "rabbitmq"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "rabbitmqctl status || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "rabbitmq-data"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      
      authorization_config {
        access_point_id = var.rabbitmq_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rabbitmq"
    }
  )
}

# ECS Service for RabbitMQ
resource "aws_ecs_service" "rabbitmq" {
  name            = "${var.project_name}-${var.environment}-rabbitmq"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.rabbitmq.arn
  desired_count   = 0  # Disabled - only needed when microservices with event messaging are deployed
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.data_services.id]
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
