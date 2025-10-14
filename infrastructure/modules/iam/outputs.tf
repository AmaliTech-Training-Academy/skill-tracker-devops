output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task.name
}

output "amplify_role_arn" {
  description = "ARN of the Amplify service role"
  value       = aws_iam_role.amplify.arn
}

output "amplify_role_name" {
  description = "Name of the Amplify service role"
  value       = aws_iam_role.amplify.name
}

output "flow_logs_role_arn" {
  description = "ARN of the VPC Flow Logs role"
  value       = var.enable_vpc_flow_logs ? aws_iam_role.flow_logs[0].arn : null
}

output "s3_access_policy_arn" {
  description = "ARN of the S3 access policy"
  value       = aws_iam_policy.ecs_s3_access.arn
}

output "rds_access_policy_arn" {
  description = "ARN of the RDS access policy"
  value       = aws_iam_policy.ecs_rds_access.arn
}

output "cloudwatch_logs_policy_arn" {
  description = "ARN of the CloudWatch Logs policy"
  value       = aws_iam_policy.ecs_cloudwatch_logs.arn
}
