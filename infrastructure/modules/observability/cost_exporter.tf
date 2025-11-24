# Lambda function to export cost data excluding credits to CloudWatch

# IAM role for Lambda
resource "aws_iam_role" "cost_exporter_lambda" {
  name = "${var.project_name}-${var.environment}-cost-exporter"

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

# Policy for Lambda to access Cost Explorer and write to CloudWatch
resource "aws_iam_role_policy" "cost_exporter_lambda" {
  name = "cost-exporter-policy"
  role = aws_iam_role.cost_exporter_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
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
}

# Lambda function code
resource "aws_lambda_function" "cost_exporter" {
  filename         = "${path.module}/lambda/cost_exporter.zip"
  function_name    = "${var.project_name}-${var.environment}-cost-exporter"
  role             = aws_iam_role.cost_exporter_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.cost_exporter_lambda.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = var.tags
}

# Package Lambda function
data "archive_file" "cost_exporter_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda/cost_exporter.zip"

  source {
    content  = file("${path.module}/lambda/cost_exporter.py")
    filename = "index.py"
  }
}

# CloudWatch log group for Lambda
resource "aws_cloudwatch_log_group" "cost_exporter" {
  name              = "/aws/lambda/${aws_lambda_function.cost_exporter.function_name}"
  retention_in_days = 7

  tags = var.tags
}

# EventBridge rule to trigger Lambda daily at 00:00 UTC
resource "aws_cloudwatch_event_rule" "cost_exporter_daily" {
  name                = "${var.project_name}-${var.environment}-cost-exporter-daily"
  description         = "Trigger cost exporter Lambda daily"
  schedule_expression = "cron(0 0 * * ? *)"

  tags = var.tags
}

# EventBridge target
resource "aws_cloudwatch_event_target" "cost_exporter_daily" {
  rule      = aws_cloudwatch_event_rule.cost_exporter_daily.name
  target_id = "CostExporterLambda"
  arn       = aws_lambda_function.cost_exporter.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "cost_exporter_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_exporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_exporter_daily.arn
}
