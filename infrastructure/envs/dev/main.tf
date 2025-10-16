locals {
 project_name = "sdt"
 environment  = "dev"

 common_tags = {
   Project     = "Skills Development Tracker"
   Environment = local.environment
   ManagedBy   = "Terraform"
 }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name         = local.project_name
  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_name = local.project_name
  environment  = local.environment

  s3_bucket_arns  = module.s3.all_bucket_arns
  rds_secret_arns = [module.rds.secrets_manager_secret_arn]

  enable_xray          = var.enable_xray
  enable_vpc_flow_logs = var.enable_vpc_flow_logs

  tags = local.common_tags
}

# S3 Module
module "s3" {
  source = "../../modules/s3"

  project_name             = local.project_name
  environment              = local.environment
  enable_versioning        = true
  cors_allowed_origins     = var.cors_allowed_origins
  logs_retention_days      = 90
  create_terraform_state_bucket = false  # Backend bucket already exists

  tags = local.common_tags
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  project_name             = local.project_name
  environment              = local.environment
  vpc_id                   = module.networking.vpc_id
  vpc_cidr                 = module.networking.vpc_cidr
  public_subnet_ids        = module.networking.public_subnet_ids
  private_subnet_ids       = module.networking.private_subnet_ids
  container_port           = var.container_port
  enable_container_insights = true
  log_retention_days       = 30
  create_alb               = true
  health_check_path        = "/health"

  services = {
    api-gateway = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8080
    }
    config-server = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8081
    }
    discovery-server = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8082
    }
    bff-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8083
    }
    user-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8084
    }
    task-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8085
    }
    analytics-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8086
    }
    payment-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8087
    }
    gamification-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8088
    }
    practice-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8089
    }
    feedback-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8090
    }
    notification-service = {
      min_capacity        = 1
      max_capacity        = 2
      cpu_target_value    = 70
      memory_target_value = 80
      port                = 8091
    }
  }

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  ecs_security_group_id     = module.ecs.ecs_tasks_security_group_id

  db_name                   = var.db_name
  db_username               = var.db_username
  db_engine_version         = "16.3"  # Updated to available version
  db_instance_class         = "db.t3.micro"
  db_allocated_storage      = 20
  db_storage_type           = "gp3"

  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "sun:04:00-sun:05:00"

  enable_enhanced_monitoring = false
  enable_performance_insights = false
  create_read_replica        = false

  max_connections           = "100"
  force_ssl                 = true

  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name          = local.project_name
  environment           = local.environment
  aws_region            = var.aws_region
  ecs_cluster_name      = module.ecs.cluster_name
  ecs_log_group         = module.ecs.log_groups["cluster"]
  rds_instance_id       = module.rds.db_instance_id
  
  # ALB alarms - uncomment after first deployment when ALB exists
  # alb_arn               = module.ecs.alb_arn
  # alb_target_group_arn  = module.ecs.target_group_arn
  
  enable_vpc_flow_logs  = var.enable_vpc_flow_logs
  log_retention_days    = 30
  alarm_email_endpoints = var.alarm_email_endpoints

  tags = local.common_tags
}

# Amplify Module - DISABLED FOR BACKEND-ONLY DEPLOYMENT
# # module "amplify" {
#  source = "../../modules/amplify"
# 
#  project_name           = local.project_name
#  environment            = local.environment
#  repository_url         = var.amplify_repository_url
#  main_branch_name       = "dev"
#  framework              = "Angular"
#  platform               = "WEB"
#  build_output_directory = "dist/SkillBoost/browser"
# 
#  environment_variables = {
#    NG_APP_URL  = "https://jsonplaceholder.typicode.com"
#    ENVIRONMENT = local.environment
#  }
# 
#  enable_auto_branch_creation   = true
#  enable_branch_auto_build      = true
#  enable_branch_auto_deletion   = true
#  auto_branch_creation_patterns = ["feature/*", "dev/*"]
# 
#  github_access_token = var.github_access_token
# 
#  create_webhook = false
# 
#  tags = local.common_tags
# }
