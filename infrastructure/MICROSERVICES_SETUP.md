# Microservices Architecture Setup Guide

## 🏗️ Architecture Overview

Your SDT application uses a **microservices architecture** with:
- **11 Backend Services** (Spring Boot/Java)
- **5 PostgreSQL Databases** (on different ports)
- **4 MongoDB Databases** (on different ports)
- **1 Angular Frontend** (AWS Amplify)

## 📊 Service & Port Mapping

### Backend Services

| Service | Port | Database | Database Port |
|---------|------|----------|---------------|
| API Gateway | 8080 | - | - |
| Config Server | 8081 | - | - |
| Discovery Server | 8082 | - | - |
| BFF Service | 8083 | - | - |
| User Service | 8084 | PostgreSQL | 5432 |
| Task Service | 8085 | PostgreSQL + MongoDB | 5433, 27017 |
| Analytics Service | 8086 | MongoDB | 27018 |
| Payment Service | 8087 | PostgreSQL | 5435 |
| Gamification Service | 8088 | MongoDB | 27019 |
| Practice Service | 8089 | PostgreSQL | 5436 |
| Feedback Service | 8090 | PostgreSQL | 5434 |
| Notification Service | 8091 | MongoDB | 27020 |

## 🗄️ Database Architecture

### PostgreSQL Databases (5 instances)

You'll need to set up multiple PostgreSQL databases:

**Option 1: Single RDS Instance with Multiple Databases (Recommended for Dev/Staging)**
- One RDS PostgreSQL instance
- Multiple databases within it
- Different ports mapped via application configuration

**Option 2: Multiple RDS Instances (Production)**
- Separate RDS instance per service
- Better isolation
- Higher cost

### MongoDB Databases (4 instances)

You have two options:

**Option 1: Amazon DocumentDB (Managed)**
```hcl
# Recommended for production
# Compatible with MongoDB 3.6, 4.0, 5.0
```

**Option 2: MongoDB on ECS (Container)**
```hcl
# For dev/testing
# Run MongoDB containers on ECS
```

## 🔧 Infrastructure Configuration

### 1. What the Terraform Creates

The infrastructure **already creates**:
- ✅ VPC with public/private subnets
- ✅ ECS Cluster for all microservices
- ✅ ECR repositories (need to add new ones)
- ✅ Application Load Balancer
- ✅ Security groups with port ranges 8080-8091
- ✅ PostgreSQL support (port range 5432-5436)
- ✅ MongoDB support (port range 27017-27020)
- ✅ CloudWatch logging per service
- ✅ Auto-scaling configuration

### 2. What You Need to Add

#### A. Update ECR Repositories

The current setup has 4 ECR repos. You need 11. Update `infrastructure/modules/ecs/ecr.tf`:

```hcl
# You'll need to add ECR repositories for:
# - api-gateway
# - config-server
# - discovery-server
# - bff-service
# - user-service
# - task-service
# - analytics-service
# - payment-service
# - gamification-service
# - practice-service
# - feedback-service
# - notification-service
```

#### B. Add MongoDB/DocumentDB Module

Create `infrastructure/modules/documentdb/` for MongoDB:

**Option 1: DocumentDB (Recommended)**
```hcl
resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.environment}-docdb"
  engine                  = "docdb"
  master_username         = var.docdb_username
  master_password         = random_password.docdb_password.result
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot     = var.environment != "production"
  db_subnet_group_name    = aws_docdb_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.docdb.id]
  
  # Multiple instances for your 4 MongoDB databases
  # You can create separate clusters or use one with multiple instances
}
```

#### C. Multiple PostgreSQL Databases

Two approaches:

**Approach 1: Single RDS with Multiple Databases** (Easier, Cheaper)
```sql
-- After RDS is created, connect and run:
CREATE DATABASE user_db;
CREATE DATABASE task_db;
CREATE DATABASE payment_db;
CREATE DATABASE practice_db;
CREATE DATABASE feedback_db;
```

**Approach 2: Multiple RDS Instances** (Better isolation)
```hcl
# Create 5 separate RDS instances
# More expensive but better isolation
```

## 📝 Configuration Steps

### Step 1: Update ECR Repositories

I'll create a script to generate all ECR repos:

```bash
# Run this after initial terraform apply
cd infrastructure/envs/dev
terraform apply -target=module.ecs.aws_ecr_repository
```

### Step 2: Database Setup

**For PostgreSQL:**
```hcl
# In your terraform.tfvars
db_name = "sdt_main"  # Main database
# Additional databases created manually or via migration scripts
```

**For MongoDB/DocumentDB:**
```hcl
# Add to terraform.tfvars
enable_documentdb = true
documentdb_instance_count = 4  # For 4 MongoDB instances
```

### Step 3: Service Configuration

Each service needs environment variables:

**Example for User Service (8084 → PostgreSQL 5432):**
```json
{
  "environment": [
    {"name": "SERVER_PORT", "value": "8084"},
    {"name": "DB_HOST", "valueFrom": "rds-endpoint"},
    {"name": "DB_PORT", "value": "5432"},
    {"name": "DB_NAME", "value": "user_db"},
    {"name": "SPRING_PROFILES_ACTIVE", "value": "dev"},
    {"name": "CONFIG_SERVER_URL", "value": "http://config-server:8081"},
    {"name": "EUREKA_SERVER_URL", "value": "http://discovery-server:8082/eureka"}
  ]
}
```

**Example for Task Service (8085 → PostgreSQL 5433 + MongoDB 27017):**
```json
{
  "environment": [
    {"name": "SERVER_PORT", "value": "8085"},
    {"name": "POSTGRES_HOST", "valueFrom": "rds-endpoint"},
    {"name": "POSTGRES_PORT", "value": "5433"},
    {"name": "POSTGRES_DB", "value": "task_db"},
    {"name": "MONGODB_HOST", "valueFrom": "docdb-endpoint"},
    {"name": "MONGODB_PORT", "value": "27017"},
    {"name": "MONGODB_DB", "value": "task_db"}
  ]
}
```

## 🚀 Deployment Sequence

### Phase 1: Infrastructure (Terraform)
```bash
cd infrastructure
make apply ENV=dev
```

This creates:
- VPC, Subnets, Security Groups
- ECS Cluster
- RDS PostgreSQL
- DocumentDB (if enabled)
- ECR Repositories
- Load Balancer

### Phase 2: Database Initialization
```bash
# Connect to RDS and create additional databases
psql -h <rds-endpoint> -U sdt_admin -d sdt_main

CREATE DATABASE user_db;
CREATE DATABASE task_db;
CREATE DATABASE payment_db;
CREATE DATABASE practice_db;
CREATE DATABASE feedback_db;
```

### Phase 3: Service Deployment

Deploy in this order (respecting dependencies):

1. **Config Server** (8081) - First, as others depend on it
2. **Discovery Server** (8082) - Second, for service registration
3. **API Gateway** (8080) - Third, as entry point
4. **Core Services:**
   - User Service (8084)
   - Task Service (8085)
   - Practice Service (8089)
5. **Supporting Services:**
   - Analytics Service (8086)
   - Payment Service (8087)
   - Gamification Service (8088)
   - Feedback Service (8090)
   - Notification Service (8091)
6. **BFF Service** (8083) - Last, aggregates others

## 🔐 Security Configuration

### Database Security

**RDS Security Group:**
```hcl
# Already configured to allow ECS tasks
ingress {
  from_port       = 5432
  to_port         = 5436
  protocol        = "tcp"
  security_groups = [ecs_tasks_sg]
}
```

**DocumentDB Security Group:**
```hcl
ingress {
  from_port       = 27017
  to_port         = 27020
  protocol        = "tcp"
  security_groups = [ecs_tasks_sg]
}
```

### Service-to-Service Communication

All services can communicate via:
- Service discovery (Eureka)
- Direct service-to-service calls within VPC
- Ports 8080-8091 allowed between services

## 💰 Cost Estimates

### Development Environment

| Component | Cost/Month |
|-----------|-----------|
| RDS PostgreSQL (db.t3.micro) | $15 |
| DocumentDB (4 instances t3.medium) | $280 |
| ECS Fargate (11 services) | $150-200 |
| NAT Gateway | $32 |
| Data Transfer | $10 |
| **Total** | **~$487-527** |

### Cost Optimization Tips

**For Development:**
1. Use single RDS instance with multiple databases
2. Run MongoDB as containers on ECS instead of DocumentDB
3. Reduce service replica counts to 1
4. Use Fargate Spot pricing

**Estimated Dev Cost with Optimizations:** ~$150-200/month

## 📋 Environment Variables Template

Create a file: `service-configs.json`

```json
{
  "api-gateway": {
    "port": 8080,
    "dependencies": ["config-server", "discovery-server"]
  },
  "config-server": {
    "port": 8081,
    "dependencies": []
  },
  "discovery-server": {
    "port": 8082,
    "dependencies": ["config-server"]
  },
  "user-service": {
    "port": 8084,
    "database": {
      "type": "postgresql",
      "port": 5432,
      "name": "user_db"
    }
  }
  // ... etc for all services
}
```

## 🔧 Quick Setup Commands

```bash
# 1. Apply infrastructure
cd infrastructure
make apply ENV=dev

# 2. Get database endpoints
make output ENV=dev | grep rds_endpoint
make output ENV=dev | grep docdb_endpoint

# 3. Create databases
psql -h <endpoint> -U sdt_admin -d sdt_main -f create_databases.sql

# 4. Build and push Docker images
for service in api-gateway config-server discovery-server bff-service \
               user-service task-service analytics-service payment-service \
               gamification-service practice-service feedback-service \
               notification-service; do
  docker build -t $service:latest ./$service
  docker tag $service:latest <account>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/$service:latest
  docker push <account>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/$service:latest
done

# 5. Deploy services to ECS
# Use AWS Console or CLI to create ECS services
```

## 📚 Additional Resources

- **Service Discovery:** Use AWS Cloud Map or Eureka
- **Configuration:** Spring Cloud Config Server
- **API Gateway:** Spring Cloud Gateway or AWS API Gateway
- **Monitoring:** CloudWatch + X-Ray
- **Logging:** CloudWatch Logs (already configured)

## ⚠️ Important Notes

1. **Port Mapping:** The ports shown (8080-8091) are **container ports**. The ALB will route traffic to these.

2. **Database Ports:** PostgreSQL ports 5432-5436 and MongoDB ports 27017-27020 are for your application configuration, not infrastructure routing.

3. **Service Discovery:** Consider using:
   - Spring Cloud Netflix Eureka (already in your architecture)
   - AWS Cloud Map
   - AWS App Mesh

4. **Config Server:** Should be the first service to start. All others depend on it.

## 🆘 Troubleshooting

### Services can't connect to databases
- Check security groups
- Verify database endpoints
- Check service environment variables

### Services can't find each other
- Verify Discovery Server is running
- Check Eureka registration
- Verify VPC DNS resolution

### Out of memory errors
- Increase ECS task memory
- Check memory leaks in application
- Review JVM settings

---

**Next Steps:**
1. Review this architecture
2. Update ECR repositories (I can help with this)
3. Add DocumentDB module (I can create this)
4. Update service configurations
5. Deploy services in sequence
