# EFS File System for persistent data storage
resource "aws_efs_file_system" "data" {
  creation_token = "${var.project_name}-${var.environment}-data"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-data-efs"
    }
  )
}

# Mount targets for each private subnet
resource "aws_efs_mount_target" "data" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.data.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-${var.environment}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from ECS tasks"
    from_port       = 2049
    to_port         = 2049
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
      Name = "${var.project_name}-${var.environment}-efs-sg"
    }
  )
}

# Access Point for MongoDB
resource "aws_efs_access_point" "mongodb" {
  file_system_id = aws_efs_file_system.data.id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/mongodb"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "755"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mongodb-ap"
    }
  )
}

# Access Point for Redis
resource "aws_efs_access_point" "redis" {
  file_system_id = aws_efs_file_system.data.id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/redis"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "755"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-ap"
    }
  )
}

# Access Point for RabbitMQ
resource "aws_efs_access_point" "rabbitmq" {
  file_system_id = aws_efs_file_system.data.id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/rabbitmq"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "755"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rabbitmq-ap"
    }
  )
}
