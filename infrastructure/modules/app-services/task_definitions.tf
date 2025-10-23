locals {
  # Default container image placeholder; CI will register new revisions with real image
  default_image = "public.ecr.aws/amazonlinux/amazonlinux:2023"
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "service" {
  for_each = { for s in var.services : s.name => s }

  family                   = "${var.project_name}-${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name        = each.key,
      image       = local.default_image,
      essential   = true,
      portMappings = [
        {
          containerPort = each.value.port,
          hostPort      = each.value.port,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = lookup(var.log_groups, each.key, "${var.project_name}-${var.environment}-cluster-logs"),
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = each.key
        }
      },
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${each.value.port}/actuator/health || exit 1"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 60
      }
    }
  ])
}
