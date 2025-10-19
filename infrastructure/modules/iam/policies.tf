# S3 Access Policy for ECS Tasks
resource "aws_iam_policy" "ecs_s3_access" {
  name        = "${var.project_name}-${var.environment}-ecs-s3-access"
  description = "Allow ECS tasks to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arns
      }
    ]
  })

  tags = var.tags
}

# Attach S3 policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}

# RDS Access Policy for ECS Tasks (using Secrets Manager)
resource "aws_iam_policy" "ecs_rds_access" {
  name        = "${var.project_name}-${var.environment}-ecs-rds-access"
  description = "Allow ECS tasks to access RDS via Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.rds_secret_arns
      }
    ]
  })

  tags = var.tags
}

# Attach RDS policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_rds" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_rds_access.arn
}

# CloudWatch Logs Policy for ECS Tasks
resource "aws_iam_policy" "ecs_cloudwatch_logs" {
  name        = "${var.project_name}-${var.environment}-ecs-cloudwatch-logs"
  description = "Allow ECS tasks to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = var.tags
}

# Attach CloudWatch Logs policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_logs.arn
}

# ECR Access Policy for ECS Task Execution Role
resource "aws_iam_policy" "ecs_ecr_access" {
  name        = "${var.project_name}-${var.environment}-ecs-ecr-access"
  description = "Allow ECS to pull images from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach ECR policy to ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_ecr" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_ecr_access.arn
}

# X-Ray Access Policy (optional for distributed tracing)
resource "aws_iam_policy" "ecs_xray_access" {
  count       = var.enable_xray ? 1 : 0
  name        = "${var.project_name}-${var.environment}-ecs-xray-access"
  description = "Allow ECS tasks to send traces to X-Ray"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach X-Ray policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_xray" {
  count      = var.enable_xray ? 1 : 0
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_xray_access[0].arn
}

# EFS Access Policy for ECS Tasks
resource "aws_iam_policy" "ecs_efs_access" {
  name        = "${var.project_name}-${var.environment}-ecs-efs-access"
  description = "Allow ECS tasks to mount and access EFS file systems"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach EFS policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_efs" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_efs_access.arn
}
