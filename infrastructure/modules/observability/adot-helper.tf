# ADOT Sidecar Helper - Generates container definitions for ADOT sidecars
# This can be used in app-services module to add ADOT to existing task definitions

# Note: adot_image local is defined in adot-sidecar.tf to avoid duplication

# Function to generate ADOT sidecar container definition
# Usage: Call this from app-services module with service-specific parameters
output "generate_adot_sidecar" {
  description = "Helper function to generate ADOT sidecar container definition"
  value = {
    template = <<-EOT
      {
        "name": "aws-otel-collector",
        "image": "${local.adot_image}",
        "essential": false,
        "cpu": 256,
        "memory": 512,
        "environment": [
          {"name": "SERVICE_NAME", "value": "$${service_name}"},
          {"name": "ENVIRONMENT", "value": "${var.environment}"},
          {"name": "ECS_CLUSTER_NAME", "value": "$${cluster_name}"},
          {"name": "AWS_REGION", "value": "${var.aws_region}"},
          {"name": "PROJECT_NAME", "value": "${var.project_name}"},
          {"name": "PROMETHEUS_ENDPOINT", "value": "$${prometheus_endpoint}"},
          {"name": "SERVICE_PORT", "value": "$${service_port}"},
          {"name": "AOT_CONFIG_CONTENT", "value": ${jsonencode(templatefile("${path.module}/adot-config-template.yaml", {
            service_name = "$${service_name}"
            service_port = "$${service_port}"
          }))}}
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
          "command": ["CMD-SHELL", "wget --spider -q http://localhost:13133/ || exit 1"],
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
}

# CloudWatch Log Group for ADOT
resource "aws_cloudwatch_log_group" "adot" {
  name              = "/aws/ecs/${var.project_name}-${var.environment}-adot"
  retention_in_days = 7
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-adot-logs"
    }
  )
}
