# Quick Start Guide

## Prerequisites

```bash
# Check versions
terraform version  # >= 1.5.0
aws --version      # >= 2.0
```

## Setup (5 minutes)

### 1. Run Setup Script
```bash
cd infrastructure
./scripts/setup.sh
```

Or manually:

### 2. Create Backend
```bash
make setup-backend ENV=dev
```

### 3. Configure Variables
```bash
cp terraform.tfvars.example envs/dev/terraform.tfvars
vi envs/dev/terraform.tfvars  # Edit with your values
```

### 4. Initialize & Apply
```bash
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

## Common Commands

```bash
# Deploy to dev
make apply ENV=dev

# Deploy to staging
make apply ENV=staging

# Deploy to production
make apply ENV=production

# Show outputs
make output ENV=dev

# Destroy (careful!)
make destroy ENV=dev

# Format code
make fmt

# Validate configuration
make validate ENV=dev
```

## Get Important Values

```bash
# ECR repository URLs (for pushing images)
make output ENV=dev | grep ecr_repository_urls

# Load balancer DNS (for API calls)
make output ENV=dev | grep alb_dns_name

# RDS endpoint (for database connection)
make output ENV=dev | grep rds_endpoint

# Database credentials (from Secrets Manager)
aws secretsmanager get-secret-value --secret-id $(make output ENV=dev | grep rds_secret_arn | cut -d'"' -f2) --query SecretString --output text | jq
```

## Push Docker Image to ECR

```bash
# Login to ECR
make ecr-login

# Build, tag, and push
docker build -t auth-service .
docker tag auth-service:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/auth-service:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/auth-service:latest
```

## Troubleshooting

### Backend initialization fails
```bash
make setup-backend ENV=dev
```

### State locked
```bash
cd envs/dev
terraform force-unlock <lock-id>
```

### Check AWS credentials
```bash
aws sts get-caller-identity
```

## Next Steps

1. Infrastructure deployed
2. Build and push Docker images to ECR
3. Deploy services to ECS
4. Deploy Angular frontend to Amplify
5. Check CloudWatch dashboards
6. 🔔 Subscribe to SNS alarm notifications

## Important URLs

After deployment, find these in outputs:

- **Frontend**: Amplify URL from `amplify_app_url`
- **Backend API**: ALB DNS from `alb_dns_name`
- **ECR Repos**: From `ecr_repository_urls`

## Cost Estimates

**Dev Environment** (~$50-80/month):
- RDS db.t3.micro: ~$15
- ECS Fargate: ~$20-30
- NAT Gateway: ~$32
- Data transfer: ~$5
- Other services: ~$3-5

**Production Environment** (~$400-600/month):
- RDS db.r5.large Multi-AZ: ~$280
- ECS Fargate: ~$80-150
- NAT Gateways (2): ~$64
- Data transfer: ~$20
- Other services: ~$10-20

## Security Checklist

- [ ] Review `terraform.tfvars` - no secrets committed
- [ ] Setup MFA on AWS account
- [ ] Configure alarm email notifications
- [ ] Review security group rules
- [ ] Enable VPC Flow Logs (staging/production)
- [ ] Setup CloudTrail (optional)
- [ ] Configure backup notifications
- [ ] Review IAM policies

