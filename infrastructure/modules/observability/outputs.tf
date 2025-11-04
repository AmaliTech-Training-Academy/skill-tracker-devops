output "instance_id" {
  description = "ID of the monitoring EC2 instance"
  value       = aws_instance.monitoring.id
}

output "instance_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the monitoring instance"
  value       = aws_instance.monitoring.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_elastic_ip ? aws_eip.monitoring[0].public_ip : null
}

output "prometheus_url" {
  description = "Prometheus web UI URL"
  value       = "http://${var.create_elastic_ip ? aws_eip.monitoring[0].public_ip : aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana web UI URL"
  value       = "http://${var.create_elastic_ip ? aws_eip.monitoring[0].public_ip : aws_instance.monitoring.public_ip}:3000"
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint for ADOT remote write"
  value       = "http://${aws_instance.monitoring.private_ip}:9090/api/v1/write"
}

output "security_group_id" {
  description = "Security group ID of the monitoring instance"
  value       = aws_security_group.monitoring.id
}

output "iam_role_arn" {
  description = "IAM role ARN of the monitoring instance"
  value       = aws_iam_role.monitoring.arn
}
