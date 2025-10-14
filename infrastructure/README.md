# Skills Development Tracker (SDT) - Infrastructure

This repository contains the Terraform infrastructure code for the Skills Development Tracker (SDT) application, deployed on AWS using a microservices architecture.

## 🏗️ Architecture Overview

- **Region**: us-east-1
- **Compute**: Amazon ECS (Fargate) with auto-scaling
- **Database**: Amazon RDS PostgreSQL (Multi-AZ in production)
- **Storage**: Amazon S3 for user uploads, static assets, and logs
- **Frontend**: AWS Amplify hosting (Angular application)
- **Networking**: VPC with public and private subnets across 2 AZs
- **Load Balancing**: Application Load Balancer
- **Monitoring**: CloudWatch dashboards, metrics, and alarms
- **Container Registry**: Amazon ECR

## 📁 Project Structure

```
infrastructure/
├── modules/
│   ├── networking/        # VPC, subnets, IGW, NAT
│   ├── ecs/              # ECS cluster, ECR, logs, auto-scaling
│   ├── iam/              # IAM roles and policies
│   ├── s3/               # S3 buckets
│   ├── rds/              # PostgreSQL database
│   ├── monitoring/       # CloudWatch dashboards and alarms
│   └── amplify/          # Frontend hosting
├── envs/
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── production/       # Production environment
├── Makefile              # Convenient commands
├── terraform.tfvars.example
└── README.md
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0
3. **Make** (optional, but recommended)

### Initial Setup

1. **Clone the repository**:
   ```bash
   cd infrastructure
   ```

2. **Create the Terraform backend** (S3 + DynamoDB):
   ```bash
   make setup-backend ENV=dev
   make setup-backend ENV=staging
   make setup-backend ENV=production
   ```

3. **Copy and customize variables**:
   ```bash
   cp terraform.tfvars.example envs/dev/terraform.tfvars
   # Edit envs/dev/terraform.tfvars with your values
   ```

4. **Initialize Terraform**:
   ```bash
   make init ENV=dev
   ```

5. **Plan the infrastructure**:
   ```bash
   make plan ENV=dev
   ```

6. **Apply the infrastructure**:
   ```bash
   make apply ENV=dev
   ```

## 🔧 Usage

### Using Make Commands

```bash
# Initialize Terraform
make init ENV=dev

# Plan changes
make plan ENV=dev

# Apply changes
make apply ENV=dev

# Show outputs
make output ENV=dev

# Validate configuration
make validate ENV=dev

# Format Terraform files
make fmt

# Destroy infrastructure (BE CAREFUL!)
make destroy ENV=dev
```

### Using Terraform Directly

```bash
cd envs/dev

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Show outputs
terraform output

# Destroy
terraform destroy
```

## 🌍 Environments

### Development (dev)
- **VPC CIDR**: 10.0.0.0/16
- **RDS Instance**: db.t3.micro
- **ECS Min/Max**: 1-2 tasks per service
- **Multi-AZ**: No
- **Backups**: 7 days
- **Monitoring**: Basic

### Staging (staging)
- **VPC CIDR**: 10.1.0.0/16
- **RDS Instance**: db.t3.small
- **ECS Min/Max**: 1-4 tasks per service
- **Multi-AZ**: No
- **Backups**: 14 days
- **Monitoring**: Enhanced with Performance Insights

### Production (production)
- **VPC CIDR**: 10.2.0.0/16
- **RDS Instance**: db.r5.large (Multi-AZ)
- **ECS Min/Max**: 2-8 tasks per service
- **Multi-AZ**: Yes
- **Backups**: 30 days
- **Read Replica**: Yes
- **Monitoring**: Full monitoring with VPC Flow Logs, X-Ray

## 📦 Services

The infrastructure supports four microservices and an Angular frontend:

**Backend Services:**
1. **auth-service** - Authentication and authorization
2. **content-service** - Content management
3. **submission-service** - User submissions handling
4. **sandbox-runner** - Code execution sandbox

**Frontend:**
- **Angular App** - Hosted on AWS Amplify with automatic deployments

Each service has its own:
- ECR repository
- CloudWatch log group
- Auto-scaling configuration

## 🔐 Security

- **Encryption at rest**: All RDS and S3 resources encrypted
- **Encryption in transit**: SSL/TLS enforced
- **Network isolation**: Private subnets for compute and database
- **Secrets management**: AWS Secrets Manager for database credentials
- **IAM**: Least-privilege roles for all services
- **Security groups**: Restrictive ingress/egress rules

## 📊 Monitoring & Alarms

CloudWatch alarms configured for:
- ECS CPU/Memory utilization
- RDS CPU utilization
- RDS storage space
- RDS connection count
- ALB unhealthy targets
- ALB 5XX errors
- ALB response time

## 🔄 CI/CD Integration

The infrastructure is designed to integrate with CI/CD pipelines:

1. **ECR Repositories**: Push Docker images to ECR
2. **ECS Services**: Update task definitions and services
3. **Amplify**: Auto-deploy frontend on git push

### ECR Login

```bash
make ecr-login
```

### Example Deploy Flow

```bash
# Build and push Docker image
docker build -t auth-service:latest .
docker tag auth-service:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/auth-service:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/auth-service:latest

# Update ECS service (via CLI or CI/CD)
aws ecs update-service \
  --cluster sdt-dev-cluster \
  --service auth-service \
  --force-new-deployment
```

## 📝 Outputs

After applying, you'll get important outputs:

```bash
make output ENV=dev
```

Key outputs include:
- **vpc_id**: VPC identifier
- **ecs_cluster_name**: ECS cluster name
- **ecr_repository_urls**: Docker image repository URLs
- **alb_dns_name**: Load balancer DNS name
- **rds_endpoint**: Database endpoint
- **rds_secret_arn**: Database credentials secret ARN
- **s3_buckets**: S3 bucket names
- **amplify_app_url**: Frontend application URL

## 🔄 State Management

Terraform state is stored in:
- **S3 Bucket**: `sdt-terraform-state`
- **DynamoDB Table**: `sdt-<env>-locks`
- **Encryption**: Enabled
- **Versioning**: Enabled

State file paths:
- Dev: `envs/dev/terraform.tfstate`
- Staging: `envs/staging/terraform.tfstate`
- Production: `envs/production/terraform.tfstate`

## 🧪 Testing Changes

1. Always test in `dev` first
2. Plan changes carefully: `make plan ENV=dev`
3. Review the plan output thoroughly
4. Apply changes: `make apply ENV=dev`
5. Verify outputs and resources
6. Promote to staging, then production

## 🆘 Troubleshooting

### Issue: Backend initialization fails

```bash
# Ensure backend resources exist
make setup-backend ENV=dev
```

### Issue: Resource already exists

Check if resources were created outside Terraform. Consider importing:

```bash
terraform import aws_s3_bucket.example bucket-name
```

### Issue: State lock

If a previous apply failed, unlock state:

```bash
cd envs/dev
terraform force-unlock <lock-id>
```

## 🔒 Best Practices

1. **Never commit secrets**: Use environment variables or AWS Secrets Manager
2. **Review plans**: Always run `plan` before `apply`
3. **Use workspaces carefully**: Prefer separate directories for environments
4. **Tag resources**: All resources are tagged with Project, Environment, ManagedBy
5. **Enable deletion protection**: Production RDS has deletion protection enabled
6. **Backup state**: S3 versioning is enabled for state files
7. **Limit access**: Restrict who can apply production changes

