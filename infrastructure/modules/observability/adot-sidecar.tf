# ADOT Sidecar Container Definition Template
# This file provides a reusable template for adding ADOT sidecars to ECS task definitions

locals {
  # ADOT Collector image
  adot_image = "public.ecr.aws/aws-observability/aws-otel-collector:v0.35.0"
  
  # ADOT configuration as base64 encoded string
  adot_config_content = file("${path.module}/adot-config.yaml")
}

# SSM Parameter to store ADOT configuration
resource "aws_ssm_parameter" "adot_config" {
  name        = "/${var.project_name}/${var.environment}/adot/config"
  description = "ADOT Collector configuration for ${var.environment}"
  type        = "String"
  value       = local.adot_config_content
  
  tags = var.tags
}

# Output the ADOT container definition template
output "adot_container_definition" {
  description = "ADOT sidecar container definition template"
  value = {
    name      = "aws-otel-collector"
    image     = local.adot_image
    essential = false
    cpu       = 256
    memory    = 512
    
    command = ["--config=/etc/ecs/otel-config.yaml"]
    
    environment = [
      {
        name  = "AOT_CONFIG_CONTENT"
        value = local.adot_config_content
      }
    ]
    
    secrets = []
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/ecs/${var.project_name}-${var.environment}-adot"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "adot"
        "awslogs-create-group"  = "true"
      }
    }
    
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:13133/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
    
    portMappings = [
      {
        containerPort = 4317
        protocol      = "tcp"
        name          = "otlp-grpc"
      },
      {
        containerPort = 4318
        protocol      = "tcp"
        name          = "otlp-http"
      },
      {
        containerPort = 13133
        protocol      = "tcp"
        name          = "health-check"
      },
      {
        containerPort = 8888
        protocol      = "tcp"
        name          = "metrics"
      }
    ]
  }
}

# Function to generate ADOT container definition with service-specific config
output "adot_container_definition_function" {
  description = "Function to generate ADOT container definition for a specific service"
  value = <<-EOT
    Use this template to add ADOT sidecar to your ECS task definitions:
    
    {
      "name": "aws-otel-collector",
      "image": "${local.adot_image}",
      "essential": false,
      "cpu": 256,
      "memory": 512,
      "command": ["--config=/etc/ecs/otel-config.yaml"],
      "environment": [
        {"name": "SERVICE_NAME", "value": "<service-name>"},
        {"name": "ENVIRONMENT", "value": "${var.environment}"},
        {"name": "ECS_CLUSTER_NAME", "value": "<cluster-name>"},
        {"name": "ECS_TASK_FAMILY", "value": "<task-family>"},
        {"name": "AWS_REGION", "value": "${var.aws_region}"},
        {"name": "PROJECT_NAME", "value": "${var.project_name}"},
        {"name": "PROMETHEUS_ENDPOINT", "value": "<prometheus-endpoint>"},
        {"name": "AOT_CONFIG_CONTENT", "value": "${replace(local.adot_config_content, "\n", "\\n")}"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/aws/ecs/${var.project_name}-${var.environment}-adot",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "adot",
          "awslogs-create-group": "true"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:13133/ || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "portMappings": [
        {"containerPort": 4317, "protocol": "tcp"},
        {"containerPort": 4318, "protocol": "tcp"},
        {"containerPort": 13133, "protocol": "tcp"},
        {"containerPort": 8888, "protocol": "tcp"}
      ]
    }
  EOT
}
