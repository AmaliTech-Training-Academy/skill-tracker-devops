# Data Services Setup Guide

## 🎯 Overview

This guide covers the **MongoDB, Redis, and RabbitMQ** services running as ECS containers with persistent storage.

---

## 📦 What Was Added

### **1. EFS Module** (`modules/efs/`)
- **Persistent storage** for MongoDB, Redis, and RabbitMQ data
- **3 Access Points** (one per service for isolated storage)
- **Encryption** at rest and in transit
- **Lifecycle Policy** (transitions to Infrequent Access after 30 days)

**Cost:** ~$3-5/month for 5GB storage

### **2. Data Services Module** (`modules/data-services/`)
- **MongoDB 7** container (port 27017)
- **Redis 7** container (port 6379)
- **RabbitMQ 3** with management UI (ports 5672, 15672)
- **Service Discovery** via AWS Cloud Map
- **Auto-generated credentials** stored in Secrets Manager
- **CloudWatch Logs** for each service

**Cost:** ~$10-15/month for 3 small Fargate tasks

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│  Private Subnet (ECS Tasks)                     │
│                                                  │
│  ┌──────────────┐    ┌──────────────┐          │
│  │   MongoDB    │    │    Redis     │          │
│  │   (Fargate)  │    │  (Fargate)   │          │
│  │   Port 27017 │    │  Port 6379   │          │
│  └──────┬───────┘    └──────┬───────┘          │
│         │                   │                   │
│         └───────┬───────────┘                   │
│                 │                                │
│         ┌───────▼───────┐                       │
│         │   RabbitMQ    │                       │
│         │   (Fargate)   │                       │
│         │ 5672 | 15672  │                       │
│         └───────┬───────┘                       │
│                 │                                │
└─────────────────┼────────────────────────────────┘
                  │
         ┌────────▼─────────┐
         │       EFS        │
         │  Persistent Data │
         │  /mongodb        │
         │  /redis          │
         │  /rabbitmq       │
         └──────────────────┘
```

---

## 🔌 Service Endpoints

After deployment, your microservices can connect using:

### **MongoDB**
```yaml
# Connection string
mongodb://admin:<password>@mongodb.dev.sdt.local:27017/audit_db

# Environment variables for Java/Spring Boot
MONGODB_HOST: mongodb.dev.sdt.local
MONGODB_PORT: 27017
MONGODB_DATABASE: audit_db
MONGODB_USERNAME: admin
MONGODB_PASSWORD: <from_secrets_manager>
```

### **Redis**
```yaml
# Connection string
redis://redis.dev.sdt.local:6379

# Environment variables
REDIS_HOST: redis.dev.sdt.local
REDIS_PORT: 6379
```

### **RabbitMQ**
```yaml
# AMQP Connection
amqp://admin:<password>@rabbitmq.dev.sdt.local:5672

# Management UI (internal only)
http://rabbitmq.dev.sdt.local:15672

# Environment variables
RABBITMQ_HOST: rabbitmq.dev.sdt.local
RABBITMQ_PORT: 5672
RABBITMQ_MANAGEMENT_PORT: 15672
RABBITMQ_USERNAME: admin
RABBITMQ_PASSWORD: <from_secrets_manager>
```

---

## 🔐 Retrieving Credentials

### **MongoDB Credentials**
```bash
# Get the secret ARN
aws secretsmanager get-secret-value \
  --secret-id sdt-dev-mongodb-credentials \
  --query SecretString \
  --output text | jq -r '.password'
```

### **RabbitMQ Credentials**
```bash
# Get the secret ARN
aws secretsmanager get-secret-value \
  --secret-id sdt-dev-rabbitmq-credentials \
  --query SecretString \
  --output text | jq -r '.password'
```

### **All Credentials at Once**
```bash
# After terraform apply
cd infrastructure/envs/dev

# MongoDB
terraform output -raw mongodb_secret_arn | xargs -I {} \
  aws secretsmanager get-secret-value --secret-id {} --query SecretString --output text

# RabbitMQ
terraform output -raw rabbitmq_secret_arn | xargs -I {} \
  aws secretsmanager get-secret-value --secret-id {} --query SecretString --output text
```

---

## 🚀 Deployment

### **Initialize and Apply**
```bash
cd infrastructure
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

This will create:
- ✅ EFS file system with 3 access points
- ✅ MongoDB container (512 CPU, 1GB RAM)
- ✅ Redis container (256 CPU, 512MB RAM)
- ✅ RabbitMQ container (512 CPU, 1GB RAM)
- ✅ Service Discovery (Cloud Map namespace)
- ✅ Security groups with proper ports
- ✅ Secrets in Secrets Manager
- ✅ CloudWatch log groups

**Deployment time:** ~5-7 minutes

---

## 📊 Monitoring

### **CloudWatch Logs**
```bash
# MongoDB logs
aws logs tail /ecs/sdt/dev/mongodb --follow

# Redis logs
aws logs tail /ecs/sdt/dev/redis --follow

# RabbitMQ logs
aws logs tail /ecs/sdt/dev/rabbitmq --follow
```

### **Check Service Health**
```bash
# List ECS services
aws ecs list-services --cluster sdt-dev-cluster

# Check MongoDB task
aws ecs describe-services \
  --cluster sdt-dev-cluster \
  --services sdt-dev-mongodb \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Check Redis task
aws ecs describe-services \
  --cluster sdt-dev-cluster \
  --services sdt-dev-redis \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Check RabbitMQ task
aws ecs describe-services \
  --cluster sdt-dev-cluster \
  --services sdt-dev-rabbitmq \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

---

## 🔧 Troubleshooting

### **Service Won't Start**
1. Check CloudWatch logs for errors
2. Verify EFS mount targets are available
3. Check security group rules
4. Ensure ECS task execution role has permissions

### **Can't Connect from Microservices**
1. Verify service discovery is working:
   ```bash
   aws servicediscovery list-services
   ```
2. Check DNS resolution:
   ```bash
   # From within an ECS task
   nslookup mongodb.dev.sdt.local
   ```
3. Verify security group allows traffic

### **Data Not Persisting**
1. Check EFS mount is successful in CloudWatch logs
2. Verify EFS access point permissions (uid/gid 999)
3. Check EFS mount targets are healthy

---

## 💾 Backup Strategy

### **MongoDB**
- Data stored on EFS (persistent across container restarts)
- Enable AWS Backup for EFS:
  ```bash
  # Create backup plan (manual - add to Terraform later)
  aws backup create-backup-plan \
    --backup-plan file://backup-plan.json
  ```

### **Redis**
- AOF (Append-Only File) persistence enabled
- Data written to EFS on every operation
- Can restore from EFS snapshot

### **RabbitMQ**
- Queue data stored on EFS
- Messages persist across restarts
- Consider regular EFS snapshots for production

---

## 📈 Scaling

### **Vertical Scaling (More Resources)**
Edit `modules/data-services/ecs_tasks.tf`:
```hcl
# MongoDB - increase from 512/1024 to 1024/2048
cpu    = "1024"
memory = "2048"

# Redis - increase from 256/512 to 512/1024
cpu    = "512"
memory = "1024"
```

### **Horizontal Scaling (Multiple Instances)**
**MongoDB:** Not recommended in dev (use DocumentDB for production)
**Redis:** Add Redis Cluster configuration (advanced)
**RabbitMQ:** Add clustering configuration (advanced)

---

## 💰 Cost Breakdown

| Resource | Specs | Monthly Cost |
|----------|-------|--------------|
| **EFS Storage** | 5GB (estimated) | ~$1.50 |
| **MongoDB Task** | 0.5 vCPU, 1GB RAM | ~$8 |
| **Redis Task** | 0.25 vCPU, 0.5GB RAM | ~$4 |
| **RabbitMQ Task** | 0.5 vCPU, 1GB RAM | ~$8 |
| **Data Transfer** | Minimal within VPC | ~$0.50 |
| **Secrets Manager** | 3 secrets | ~$1.20 |
| **CloudWatch Logs** | ~1GB/month | ~$0.50 |
| **TOTAL** | | **~$24/month** |

**Compare to managed services:**
- DocumentDB: ~$200/month
- ElastiCache: ~$15/month  
- Amazon MQ: ~$20/month
- **Total Managed: ~$235/month** ❌

**Savings: ~$211/month (90% cheaper!)** ✅

---

## 🎓 Best Practices

1. **Production Migration Path:**
   - Start with containers in dev
   - When traffic increases, migrate to managed services
   - DocumentDB for MongoDB (~$200/month)
   - ElastiCache for Redis (~$15/month)

2. **Security:**
   - ✅ All traffic within VPC (private subnets)
   - ✅ Encrypted at rest (EFS + Secrets Manager)
   - ✅ Encrypted in transit (EFS transit encryption)
   - ✅ No public access

3. **Monitoring:**
   - Set up CloudWatch alarms for:
     - EFS storage usage
     - ECS task health
     - Memory/CPU utilization

4. **Backups:**
   - Enable EFS backups via AWS Backup
   - Test restore procedures
   - Document recovery steps

---

## 📝 Environment Variables for Microservices

Add these to your ECS task definitions:

### **Task Service** (uses both PostgreSQL and MongoDB)
```yaml
POSTGRES_HOST: sdt-dev-postgres.chsom6csglwa.eu-west-1.rds.amazonaws.com
POSTGRES_PORT: 5433
MONGODB_HOST: mongodb.dev.sdt.local
MONGODB_PORT: 27017
```

### **Analytics Service** (MongoDB only)
```yaml
MONGODB_HOST: mongodb.dev.sdt.local
MONGODB_PORT: 27018  # Use 27017, different DB name
MONGODB_DATABASE: analytics_db
```

### **Gamification Service** (MongoDB only)
```yaml
MONGODB_HOST: mongodb.dev.sdt.local
MONGODB_PORT: 27019  # Use 27017, different DB name
MONGODB_DATABASE: gamification_db
```

### **Notification Service** (MongoDB + RabbitMQ)
```yaml
MONGODB_HOST: mongodb.dev.sdt.local
MONGODB_PORT: 27020  # Use 27017, different DB name
MONGODB_DATABASE: notification_db
RABBITMQ_HOST: rabbitmq.dev.sdt.local
RABBITMQ_PORT: 5672
```

### **All Services** (Redis caching)
```yaml
REDIS_HOST: redis.dev.sdt.local
REDIS_PORT: 6379
```

---

## ✅ Verification Checklist

After `make apply ENV=dev`:

- [ ] EFS file system created
- [ ] 3 EFS access points created
- [ ] MongoDB ECS service running (1/1 tasks)
- [ ] Redis ECS service running (1/1 tasks)
- [ ] RabbitMQ ECS service running (1/1 tasks)
- [ ] Service discovery namespace created
- [ ] All 3 services registered in Cloud Map
- [ ] MongoDB secret created in Secrets Manager
- [ ] RabbitMQ secret created in Secrets Manager
- [ ] CloudWatch log groups created
- [ ] Security groups allow proper ports

**Quick Check:**
```bash
cd infrastructure/envs/dev
terraform output
```

You should see:
```
mongodb_endpoint = "mongodb.dev.sdt.local"
redis_endpoint = "redis.dev.sdt.local"
rabbitmq_endpoint = "rabbitmq.dev.sdt.local"
```

---

## 🆘 Support

If you encounter issues:

1. **Check logs first:**
   ```bash
   aws logs tail /ecs/sdt/dev/mongodb --follow
   ```

2. **Verify EFS mounts:**
   - CloudWatch logs will show mount errors
   - Check EFS console for mount target status

3. **Test connectivity:**
   - Deploy a test container in the same VPC
   - Try connecting to service endpoints

4. **Review security groups:**
   ```bash
   aws ec2 describe-security-groups \
     --filters Name=tag:Name,Values=sdt-dev-data-services-sg
   ```

---

**Next Steps:** Apply the infrastructure, then update your microservices to use these endpoints! 🚀
