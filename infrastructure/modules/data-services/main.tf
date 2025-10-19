# Security Group for Data Services
resource "aws_security_group" "data_services" {
  name        = "${var.project_name}-${var.environment}-data-services-sg"
  description = "Security group for MongoDB, Redis, and RabbitMQ"
  vpc_id      = var.vpc_id

  # MongoDB ports (27017-27021)
  ingress {
    description     = "MongoDB from ECS tasks"
    from_port       = 27017
    to_port         = 27021
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  # Redis port
  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  # RabbitMQ AMQP port
  ingress {
    description     = "RabbitMQ AMQP from ECS tasks"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  # RabbitMQ Management UI
  ingress {
    description     = "RabbitMQ Management from ECS tasks"
    from_port       = 15672
    to_port         = 15672
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-data-services-sg"
    }
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "mongodb" {
  name              = "/ecs/${var.project_name}/${var.environment}/mongodb"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = "mongodb"
    }
  )
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/${var.project_name}/${var.environment}/redis"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = "redis"
    }
  )
}

resource "aws_cloudwatch_log_group" "rabbitmq" {
  name              = "/ecs/${var.project_name}/${var.environment}/rabbitmq"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Service = "rabbitmq"
    }
  )
}
