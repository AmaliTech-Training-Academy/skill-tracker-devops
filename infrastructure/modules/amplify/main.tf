# Amplify App
resource "aws_amplify_app" "frontend" {
  name       = "${var.project_name}-${var.environment}-frontend"
  repository = var.repository_url

  # Build settings
  build_spec = var.build_spec != "" ? var.build_spec : <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
            - echo "Creating .env file with environment variables"
            - echo "NG_APP_URL=$NG_APP_URL" > .env
            - cat .env
        build:
          commands:
            - npx ng build
      artifacts:
        baseDirectory: ${var.build_output_directory}
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  # Environment variables
  environment_variables = var.environment_variables

  # Enable auto branch creation for feature branches
  enable_auto_branch_creation = var.enable_auto_branch_creation
  enable_branch_auto_build    = var.enable_branch_auto_build
  enable_branch_auto_deletion = var.enable_branch_auto_deletion

  # Auto branch creation patterns
  auto_branch_creation_patterns = var.auto_branch_creation_patterns

  # Auto branch creation config
  auto_branch_creation_config {
    enable_auto_build = true
    framework         = var.framework
    stage             = "DEVELOPMENT"
  }

  # Custom rules for redirects and rewrites
  dynamic "custom_rule" {
    for_each = var.custom_rules
    content {
      source = custom_rule.value.source
      status = custom_rule.value.status
      target = custom_rule.value.target
    }
  }

  # OAuth token for private repositories (only if provided)
  access_token = var.github_access_token != "" ? var.github_access_token : null

  # IAM service role (optional)
  iam_service_role_arn = var.iam_service_role_arn != "" ? var.iam_service_role_arn : null

  # Platform
  platform = var.platform

  tags = var.tags
}

# Amplify Branch for main/master
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.main_branch_name

  framework = var.framework
  stage     = var.environment == "production" ? "PRODUCTION" : var.environment == "staging" ? "STAGING" : "DEVELOPMENT"

  enable_auto_build = true

  environment_variables = var.branch_environment_variables

  tags = var.tags
}

# Amplify Domain Association (optional)
resource "aws_amplify_domain_association" "main" {
  count       = var.domain_name != "" ? 1 : 0
  app_id      = aws_amplify_app.frontend.id
  domain_name = var.domain_name

  # Subdomain settings
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = var.environment == "production" ? "" : var.environment
  }

  # Wait for DNS verification
  wait_for_verification = false
}

# Amplify Webhook for manual deployments
resource "aws_amplify_webhook" "main" {
  count       = var.create_webhook ? 1 : 0
  app_id      = aws_amplify_app.frontend.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Webhook for ${var.environment} deployments"
}
