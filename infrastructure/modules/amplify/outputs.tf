output "app_id" {
  description = "ID of the Amplify app"
  value       = aws_amplify_app.frontend.id
}

output "app_arn" {
  description = "ARN of the Amplify app"
  value       = aws_amplify_app.frontend.arn
}

output "default_domain" {
  description = "Default domain of the Amplify app"
  value       = aws_amplify_app.frontend.default_domain
}

output "app_url" {
  description = "URL of the Amplify app"
  value       = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.frontend.default_domain}"
}

output "branch_name" {
  description = "Name of the deployed branch"
  value       = aws_amplify_branch.main.branch_name
}

output "custom_domain" {
  description = "Custom domain name (if configured)"
  value       = var.domain_name != "" ? var.domain_name : null
}

output "webhook_url" {
  description = "Webhook URL for manual deployments"
  value       = var.create_webhook ? aws_amplify_webhook.main[0].url : null
  sensitive   = true
}

output "domain_association_certificate_verification_dns_record" {
  description = "DNS record for domain verification"
  value       = var.domain_name != "" ? aws_amplify_domain_association.main[0].certificate_verification_dns_record : null
}
