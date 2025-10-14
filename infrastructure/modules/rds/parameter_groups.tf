# DB Parameter Group for PostgreSQL
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-postgres-params"
  family = "postgres${split(".", var.db_engine_version)[0]}"

  description = "Custom parameter group for ${var.project_name} ${var.environment}"

  # Logging parameters
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "all"
    apply_method = "pending-reboot"
  }

  # Performance parameters
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "pg_stat_statements.track"
    value = "all"
  }

  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  # Memory parameters (adjust based on instance size)
  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/32768}"
  }

  parameter {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory/16384}"
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "2097151"
  }

  parameter {
    name  = "work_mem"
    value = "16384"
  }

  # Checkpoint parameters
  parameter {
    name  = "checkpoint_completion_target"
    value = "0.9"
  }

  parameter {
    name  = "wal_buffers"
    value = "2048"
  }

  # SSL/TLS enforcement
  parameter {
    name  = "rds.force_ssl"
    value = var.force_ssl ? "1" : "0"
    apply_method = "pending-reboot"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-postgres-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
