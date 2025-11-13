# CloudWatch Logs Export to S3
# This configuration automatically exports CloudWatch logs to S3 for long-term storage

# IAM Role for CloudWatch Logs to write to S3
resource "aws_iam_role" "cloudwatch_logs_export" {
  name = "${var.project_name}-${var.environment}-cloudwatch-logs-export"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for CloudWatch Logs to write to S3
resource "aws_iam_role_policy" "cloudwatch_logs_export" {
  name = "${var.project_name}-${var.environment}-cloudwatch-logs-export-policy"
  role = aws_iam_role.cloudwatch_logs_export.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          var.app_logs_bucket_arn,
          "${var.app_logs_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Lambda function for automated log export
resource "aws_lambda_function" "log_exporter" {
  count = var.enable_log_export_to_s3 ? 1 : 0

  filename         = data.archive_file.log_exporter_zip[0].output_path
  function_name    = "${var.project_name}-${var.environment}-log-exporter"
  role            = aws_iam_role.lambda_log_exporter[0].arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900  # 15 minutes to handle sequential processing and retries

  source_code_hash = data.archive_file.log_exporter_zip[0].output_base64sha256

  environment {
    variables = {
      S3_BUCKET = var.app_logs_bucket_id
      LOG_GROUPS = jsonencode([
        for service in var.service_names : "/ecs/${var.project_name}/${var.environment}/${service}"
      ])
    }
  }

  tags = var.tags
}

# Lambda function code
data "archive_file" "log_exporter_zip" {
  count = var.enable_log_export_to_s3 ? 1 : 0

  type        = "zip"
  output_path = "/tmp/log_exporter.zip"
  
  source {
    content = templatefile("${path.module}/templates/log_exporter.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_log_exporter" {
  count = var.enable_log_export_to_s3 ? 1 : 0

  name = "${var.project_name}-${var.environment}-lambda-log-exporter"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_log_exporter" {
  count = var.enable_log_export_to_s3 ? 1 : 0

  name = "${var.project_name}-${var.environment}-lambda-log-exporter-policy"
  role = aws_iam_role.lambda_log_exporter[0].id

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
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateExportTask",
          "logs:DescribeExportTasks",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          var.app_logs_bucket_arn,
          "${var.app_logs_bucket_arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch Event Rule to trigger hourly log export
resource "aws_cloudwatch_event_rule" "hourly_log_export" {
  count = var.enable_log_export_to_s3 ? 1 : 0

  name                = "${var.project_name}-${var.environment}-hourly-log-export"
  description         = "Trigger hourly log export to S3"
  schedule_expression = "cron(0 * * * ? *)" # Every hour at minute 0

  tags = var.tags
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  count = var.enable_log_export_to_s3 ? 1 : 0

  rule      = aws_cloudwatch_event_rule.hourly_log_export[0].name
  target_id = "LogExporterTarget"
  arn       = aws_lambda_function.log_exporter[0].arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.enable_log_export_to_s3 ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_exporter[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly_log_export[0].arn
}
