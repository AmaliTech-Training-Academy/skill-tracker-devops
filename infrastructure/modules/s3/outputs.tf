output "user_uploads_bucket_id" {
  description = "ID of the user uploads bucket"
  value       = aws_s3_bucket.user_uploads.id
}

output "user_uploads_bucket_arn" {
  description = "ARN of the user uploads bucket"
  value       = aws_s3_bucket.user_uploads.arn
}

output "user_uploads_bucket_domain_name" {
  description = "Domain name of the user uploads bucket"
  value       = aws_s3_bucket.user_uploads.bucket_domain_name
}

output "static_assets_bucket_id" {
  description = "ID of the static assets bucket"
  value       = aws_s3_bucket.static_assets.id
}

output "static_assets_bucket_arn" {
  description = "ARN of the static assets bucket"
  value       = aws_s3_bucket.static_assets.arn
}

output "static_assets_bucket_domain_name" {
  description = "Domain name of the static assets bucket"
  value       = aws_s3_bucket.static_assets.bucket_domain_name
}

output "app_logs_bucket_id" {
  description = "ID of the application logs bucket"
  value       = aws_s3_bucket.app_logs.id
}

output "app_logs_bucket_arn" {
  description = "ARN of the application logs bucket"
  value       = aws_s3_bucket.app_logs.arn
}

output "terraform_state_bucket_id" {
  description = "ID of the Terraform state bucket"
  value       = var.create_terraform_state_bucket ? aws_s3_bucket.terraform_state[0].id : null
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = var.create_terraform_state_bucket ? aws_s3_bucket.terraform_state[0].arn : null
}

output "all_bucket_arns" {
  description = "List of all S3 bucket ARNs"
  value = concat(
    [
      aws_s3_bucket.user_uploads.arn,
      "${aws_s3_bucket.user_uploads.arn}/*",
      aws_s3_bucket.static_assets.arn,
      "${aws_s3_bucket.static_assets.arn}/*",
      aws_s3_bucket.app_logs.arn,
      "${aws_s3_bucket.app_logs.arn}/*"
    ],
    var.create_terraform_state_bucket ? [
      aws_s3_bucket.terraform_state[0].arn,
      "${aws_s3_bucket.terraform_state[0].arn}/*"
    ] : []
  )
}
