# Backend-Only Deployment Guide

## 🎯 Goal
Deploy the complete backend infrastructure for 11 microservices without the Angular frontend.

## ✅ Prerequisites Checklist

- [x] AWS CLI configured (credentials set)
- [x] Terraform installed (>= 1.5.0)
- [ ] Updated `terraform.tfvars` file
- [ ] Reviewed service architecture

## 📝 Step 1: Configure Your Variables

Edit `infrastructure/envs/dev/terraform.tfvars`:

### **Required Fields (Minimum to Deploy):**

```hcl
# AWS Configuration
aws_region = "eu-west-1"  # ✅ Already set in your AWS config

# Email for CloudWatch Alarms (REQUIRED)
alarm_email_endpoints = [
  "your-email@example.com"  # ← CHANGE THIS
]

# Database Configuration (defaults are fine)
db_name = "sdt_dev"
db_username = "sdt_admin"

# Everything else can stay as default!
```

### **Optional Fields (Can Skip for Now):**

```hcl
# Frontend-related (not needed for backend-only)
amplify_repository_url = ""  # Skip - frontend disabled
github_access_token = ""     # Skip - frontend disabled

# Cost Optimization
enable_nat_gateway = true    # Set false to save $32/month (but containers won't have internet)
enable_vpc_flow_logs = false # Keep false for dev
enable_xray = false          # Keep false for dev
```

## 🚀 Step 2: Deploy the Infrastructure

### **A. Setup Terraform Backend (One-Time)**

```bash
cd infrastructure

# Create S3 bucket and DynamoDB table for state
make setup-backend ENV=dev
```

Expected output:
```
✓ S3 bucket created: sdt-terraform-state
✓ DynamoDB table created: sdt-dev-locks
```

### **B. Initialize Terraform**

```bash
make init ENV=dev
```

Expected output:
```
Terraform has been successfully initialized!
```

### **C. Preview What Will Be Created**

```bash
make plan ENV=dev
```

This shows you everything that will be created. Review it carefully!

**Expected Resources:** ~80-85 resources including:
- 1 VPC
- 4 Subnets (2 public, 2 private)
- 1 Internet Gateway
- 1 or 2 NAT Gateways
- 1 ECS Cluster
- 11 ECR Repositories (for your microservices)
- 1 Application Load Balancer
- 1 RDS PostgreSQL Instance
- 3 S3 Buckets
- Multiple Security Groups
- CloudWatch Dashboards and Alarms
- IAM Roles and Policies

### **D. Deploy!**

```bash
make apply ENV=dev
```

Type `yes` when prompted.

⏱️ **Estimated time:** 15-20 minutes

## 📊 Step 3: Verify Deployment

### **Check Outputs**

```bash
make output ENV=dev
```

**Important outputs you'll need:**

```hcl
alb_dns_name = "sdt-dev-alb-xxxxxxxxx.eu-west-1.elb.amazonaws.com"
ecs_cluster_name = "sdt-dev-cluster"
ecr_repository_urls = {
  "api-gateway" = "123456789.dkr.ecr.eu-west-1.amazonaws.com/sdt/dev/api-gateway"
  "user-service" = "123456789.dkr.ecr.eu-west-1.amazonaws.com/sdt/dev/user-service"
  # ... all 11 services
}
rds_endpoint = "sdt-dev-db.xxxxxxxxx.eu-west-1.rds.amazonaws.com:5432"
rds_secret_arn = "arn:aws:secretsmanager:eu-west-1:xxx:secret:sdt-dev-db-xxx"
```

### **Save These Values!**

Create a file `deployment-info.txt`:

```bash
# Save outputs for reference
cd envs/dev
terraform output > ../../deployment-info.txt
```

## 🗄️ Step 4: Set Up Databases

### **A. Get Database Credentials**

```bash
# Get the secret ARN from outputs
SECRET_ARN=$(terraform output -raw rds_secret_arn)

# Get the password
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq -r .password
```

### **B. Connect to RDS**

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint | cut -d: -f1)

# Connect (you'll need to be in the VPC or use a bastion host)
psql -h $RDS_ENDPOINT -U sdt_admin -d sdt_dev
```

### **C. Create Multiple Databases**

```sql
-- Create databases for each service
CREATE DATABASE user_db;
CREATE DATABASE task_db;
CREATE DATABASE payment_db;
CREATE DATABASE practice_db;
CREATE DATABASE feedback_db;

-- Verify
\l

-- Exit
\q
```

## 🐳 Step 5: Prepare Docker Images

### **A. Login to ECR**

```bash
make ecr-login
```

Or manually:
```bash
aws ecr get-login-password --region eu-west-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com
```

### **B. Build and Push Images**

For each microservice:

```bash
# Example for config-server
cd /path/to/your/config-server

# Build
docker build -t config-server:latest .

# Tag
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker tag config-server:latest \
  $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/sdt/dev/config-server:latest

# Push
docker push \
  $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/sdt/dev/config-server:latest
```

**Repeat for all 11 services:**
1. config-server
2. discovery-server
3. api-gateway
4. bff-service
5. user-service
6. task-service
7. analytics-service
8. payment-service
9. gamification-service
10. practice-service
11. feedback-service
12. notification-service

### **C. Automated Build Script**

Save this as `build-and-push-all.sh`:

```bash
#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="eu-west-1"
PROJECT="sdt"
ENV="dev"

SERVICES=(
  "config-server"
  "discovery-server"
  "api-gateway"
  "bff-service"
  "user-service"
  "task-service"
  "analytics-service"
  "payment-service"
  "gamification-service"
  "practice-service"
  "feedback-service"
  "notification-service"
)

for SERVICE in "${SERVICES[@]}"; do
  echo "Building and pushing $SERVICE..."
  
  cd /path/to/your/backend/$SERVICE
  
  docker build -t $SERVICE:latest .
  
  docker tag $SERVICE:latest \
    $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$PROJECT/$ENV/$SERVICE:latest
  
  docker push \
    $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$PROJECT/$ENV/$SERVICE:latest
  
  echo "✓ $SERVICE pushed successfully"
done

echo "All services built and pushed!"
```

## 🎯 Step 6: Deploy Services to ECS (Manual - First Time)

For now, you'll need to create ECS Task Definitions and Services manually via AWS Console:

### **For Each Service:**

1. **Go to ECS Console** → Clusters → `sdt-dev-cluster`

2. **Create Task Definition:**
   - Launch type: Fargate
   - Task memory: 512 MB (adjust per service)
   - Task CPU: 256 (.25 vCPU) (adjust per service)
   - Container name: e.g., `config-server`
   - Image: `<account>.dkr.ecr.eu-west-1.amazonaws.com/sdt/dev/config-server:latest`
   - Port: 8081 (for config-server)
   - Environment variables (see below)

3. **Create Service:**
   - Launch type: Fargate
   - Task definition: (the one you just created)
   - Service name: e.g., `config-server`
   - Number of tasks: 1
   - VPC: `sdt-dev-vpc`
   - Subnets: Private subnets
   - Security group: `sdt-dev-ecs-tasks-sg`
   - Load balancer: `sdt-dev-alb` (for API Gateway only)

### **Environment Variables Template:**

**Config Server (8081):**
```json
{
  "environment": [
    {"name": "SERVER_PORT", "value": "8081"},
    {"name": "SPRING_PROFILES_ACTIVE", "value": "dev"}
  ]
}
```

**Discovery Server (8082):**
```json
{
  "environment": [
    {"name": "SERVER_PORT", "value": "8082"},
    {"name": "SPRING_PROFILES_ACTIVE", "value": "dev"},
    {"name": "CONFIG_SERVER_URL", "value": "http://config-server:8081"}
  ]
}
```

**User Service (8084):**
```json
{
  "environment": [
    {"name": "SERVER_PORT", "value": "8084"},
    {"name": "SPRING_PROFILES_ACTIVE", "value": "dev"},
    {"name": "CONFIG_SERVER_URL", "value": "http://config-server:8081"},
    {"name": "EUREKA_SERVER_URL", "value": "http://discovery-server:8082/eureka"}
  ],
  "secrets": [
    {
      "name": "DB_PASSWORD",
      "valueFrom": "arn:aws:secretsmanager:eu-west-1:xxx:secret:sdt-dev-db-xxx:password::"
    }
  ]
}
```

## 📈 Step 7: Monitor Your Services

### **CloudWatch Dashboards**

```bash
# Get dashboard names
terraform output monitoring_dashboards
```

Access via AWS Console → CloudWatch → Dashboards

### **View Service Logs**

```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix /ecs/sdt/dev

# Tail logs for a service
aws logs tail /ecs/sdt/dev/config-server --follow
```

### **Check Service Health**

```bash
# Via ALB (once API Gateway is deployed)
curl http://<alb-dns-name>/actuator/health

# Check ECS service status
aws ecs describe-services \
  --cluster sdt-dev-cluster \
  --services config-server
```

## ✅ What You'll Have After Deployment

- ✅ VPC with public/private subnets
- ✅ ECS Cluster ready for 11 services
- ✅ 11 ECR repositories with your images
- ✅ RDS PostgreSQL with 5 databases
- ✅ Application Load Balancer
- ✅ CloudWatch monitoring and logs
- ✅ Auto-scaling configured
- ✅ Security groups configured
- ⏳ MongoDB/DocumentDB (optional - can add later)

## 💰 Cost Estimate (Backend Only)

**Monthly costs for dev environment:**

| Component | Cost |
|-----------|------|
| RDS db.t3.micro | $15 |
| ECS Fargate (11 services) | $150-180 |
| NAT Gateway | $32 |
| Load Balancer | $16 |
| Data Transfer | $10 |
| CloudWatch | $5 |
| **Total** | **~$228-258/month** |

**Cost Optimization:**
- Set `enable_nat_gateway = false` → Save $32/month
- Use Fargate Spot → Save 70% on compute
- Reduce service replicas to 1 → Save 50% on compute

## 🔄 When Ready to Deploy Frontend

Simply uncomment these lines in `envs/dev/main.tf`:

```hcl
# Uncomment the entire amplify module block (lines 157-184)
```

Then:
```bash
make plan ENV=dev
make apply ENV=dev
```

## 🆘 Troubleshooting

### Issue: "No such bucket"
Run: `make setup-backend ENV=dev`

### Issue: "Access Denied"
Check: `aws sts get-caller-identity`

### Issue: RDS connection timeout
- Ensure you're connecting from within VPC
- Or set up a bastion host
- Or use RDS Proxy

### Issue: Docker push failed
Run: `make ecr-login` and try again

### Issue: Service won't start
- Check CloudWatch logs
- Verify environment variables
- Check database connectivity

## 📝 Next Steps Checklist

- [ ] Deploy infrastructure (`make apply ENV=dev`)
- [ ] Create databases in RDS
- [ ] Build Docker images for all services
- [ ] Push images to ECR
- [ ] Create ECS task definitions
- [ ] Deploy services in order (Config → Discovery → Others)
- [ ] Test API Gateway endpoint
- [ ] Monitor CloudWatch dashboards
- [ ] (Later) Deploy frontend

---

**Need Help?**
- Check logs: CloudWatch Logs Console
- View dashboards: CloudWatch Dashboards
- See architecture: `MICROSERVICES_SETUP.md`
- Port reference: `SERVICE_PORTS_REFERENCE.md`
