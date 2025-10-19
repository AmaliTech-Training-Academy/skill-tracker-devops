# Service Ports Quick Reference

## 🎯 For Beginners: What You Need to Know

### Your Application Has:
- **11 Microservices** (Java/Spring Boot)
- **5 PostgreSQL databases**
- **4 MongoDB databases**
- **1 Angular frontend**

## 📋 Complete Port Mapping

### Backend Services (Ports 8080-8091)

```
┌─────────────────────────┬──────┬─────────────────────────────────┐
│ Service                 │ Port │ What It Does                    │
├─────────────────────────┼──────┼─────────────────────────────────┤
│ API Gateway             │ 8080 │ Entry point for all requests    │
│ Config Server           │ 8081 │ Centralized configuration       │
│ Discovery Server        │ 8082 │ Service registry (Eureka)       │
│ BFF Service             │ 8083 │ Backend-for-Frontend aggregator │
│ User Service            │ 8084 │ User management                 │
│ Task Service            │ 8085 │ Task/assignment management      │
│ Analytics Service       │ 8086 │ Analytics and reporting         │
│ Payment Service         │ 8087 │ Payment processing              │
│ Gamification Service    │ 8088 │ Badges, points, achievements    │
│ Practice Service        │ 8089 │ Practice exercises              │
│ Feedback Service        │ 8090 │ Feedback and reviews            │
│ Notification Service    │ 8091 │ Email, SMS, push notifications  │
└─────────────────────────┴──────┴─────────────────────────────────┘
```

### Database Ports

**PostgreSQL (5 databases):**
```
┌──────────────────┬──────┬─────────────────────┐
│ Service          │ Port │ Database Name       │
├──────────────────┼──────┼─────────────────────┤
│ User Service     │ 5432 │ user_db             │
│ Task Service     │ 5433 │ task_db             │
│ Feedback Service │ 5434 │ feedback_db         │
│ Payment Service  │ 5435 │ payment_db          │
│ Practice Service │ 5436 │ practice_db         │
└──────────────────┴──────┴─────────────────────┘
```

**MongoDB (4 databases):**
```
┌────────────────────────┬───────┬──────────────────────┐
│ Service                │ Port  │ Database Name        │
├────────────────────────┼───────┼──────────────────────┤
│ Task Service           │ 27017 │ task_db              │
│ Analytics Service      │ 27018 │ analytics_db         │
│ Gamification Service   │ 27019 │ gamification_db      │
│ Notification Service   │ 27020 │ notification_db      │
└────────────────────────┴───────┴──────────────────────┘
```

## 🔗 Service Dependencies

### Startup Order (Critical!)

```
1. Config Server (8081)          ← Start FIRST
   ↓
2. Discovery Server (8082)        ← Start SECOND
   ↓
3. API Gateway (8080)             ← Start THIRD
   ↓
4. All other services (8083-8091) ← Can start in parallel
```

### Why This Order?
1. **Config Server** provides configuration to all services
2. **Discovery Server** registers all services for discovery
3. **API Gateway** routes requests to services
4. **Other services** depend on the above three

## 🏗️ What Terraform Already Set Up

✅ **Security Group Rules** - Allows traffic on ports:
- 8080-8091 (for microservices)
- 5432-5436 (for PostgreSQL)
- 27017-27020 (for MongoDB)

✅ **ECS Cluster** - Ready for all 11 services

✅ **Load Balancer** - Routes external traffic to API Gateway (8080)

✅ **Auto-scaling** - Configured for each service

## 📝 What YOU Need to Configure

### 1. In `terraform.tfvars`

Already done! The infrastructure is configured for all ports.

### 2. In Your Application Code

Each microservice needs environment variables:

**Example: User Service**
```yaml
# application.yml
server:
  port: 8084

spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST}:5432/user_db
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
eureka:
  client:
    serviceUrl:
      defaultZone: http://discovery-server:8082/eureka/
```

**Example: Task Service (uses both PostgreSQL and MongoDB)**
```yaml
# application.yml
server:
  port: 8085

spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST}:5433/task_db
  
  data:
    mongodb:
      uri: mongodb://${MONGO_HOST}:27017/task_db
```

## 🔐 Environment Variables Needed Per Service

### Services WITHOUT Databases
```bash
# Config Server, Discovery Server, API Gateway, BFF Service
SERVER_PORT=808X
SPRING_PROFILES_ACTIVE=dev
CONFIG_SERVER_URL=http://config-server:8081
EUREKA_SERVER_URL=http://discovery-server:8082/eureka
```

### Services WITH PostgreSQL Only
```bash
# User, Payment, Practice, Feedback Services
SERVER_PORT=808X
DB_HOST=<RDS_ENDPOINT>
DB_PORT=543X
DB_NAME=xxx_db
DB_USERNAME=<from_secrets_manager>
DB_PASSWORD=<from_secrets_manager>
SPRING_PROFILES_ACTIVE=dev
CONFIG_SERVER_URL=http://config-server:8081
EUREKA_SERVER_URL=http://discovery-server:8082/eureka
```

### Services WITH MongoDB Only
```bash
# Analytics, Gamification, Notification Services
SERVER_PORT=808X
MONGODB_HOST=<DOCDB_ENDPOINT>
MONGODB_PORT=270XX
MONGODB_DATABASE=xxx_db
MONGODB_USERNAME=<from_secrets_manager>
MONGODB_PASSWORD=<from_secrets_manager>
SPRING_PROFILES_ACTIVE=dev
CONFIG_SERVER_URL=http://config-server:8081
EUREKA_SERVER_URL=http://discovery-server:8082/eureka
```

### Services WITH BOTH (Task Service)
```bash
SERVER_PORT=8085

# PostgreSQL
POSTGRES_HOST=<RDS_ENDPOINT>
POSTGRES_PORT=5433
POSTGRES_DATABASE=task_db
POSTGRES_USERNAME=<from_secrets_manager>
POSTGRES_PASSWORD=<from_secrets_manager>

# MongoDB
MONGODB_HOST=<DOCDB_ENDPOINT>
MONGODB_PORT=27017
MONGODB_DATABASE=task_db
MONGODB_USERNAME=<from_secrets_manager>
MONGODB_PASSWORD=<from_secrets_manager>

SPRING_PROFILES_ACTIVE=dev
CONFIG_SERVER_URL=http://config-server:8081
EUREKA_SERVER_URL=http://discovery-server:8082/eureka
```

## 🌐 How Requests Flow

```
User/Frontend
    ↓
[Angular App on Amplify]
    ↓ (HTTPS)
[ALB - Load Balancer]
    ↓
[API Gateway - Port 8080] ← Entry point
    ↓
[Discovery Server - Port 8082] ← Finds which service to call
    ↓
[Specific Service - Ports 8083-8091]
    ↓
[Database - PostgreSQL or MongoDB]
```

## 🎨 Visual Network Diagram

```
Internet
   │
   ↓
┌──────────────────────┐
│   ALB (Port 80/443)  │
└──────────┬───────────┘
           │
   ┌───────┴────────┐
   │                │
Private Subnet    Private Subnet
   │                │
   ├─ API Gateway (8080)
   ├─ Config Server (8081)
   ├─ Discovery Server (8082)
   ├─ BFF Service (8083)
   ├─ User Service (8084) ──→ PostgreSQL (5432)
   ├─ Task Service (8085) ──→ PostgreSQL (5433) + MongoDB (27017)
   ├─ Analytics (8086) ─────→ MongoDB (27018)
   ├─ Payment (8087) ───────→ PostgreSQL (5435)
   ├─ Gamification (8088) ──→ MongoDB (27019)
   ├─ Practice (8089) ──────→ PostgreSQL (5436)
   ├─ Feedback (8090) ──────→ PostgreSQL (5434)
   └─ Notification (8091) ──→ MongoDB (27020)
```

## 📞 Inter-Service Communication

Services talk to each other using:

**Method 1: Service Discovery (Recommended)**
```java
// In your Spring Boot service
@LoadBalanced
RestTemplate restTemplate;

// Call another service by name
String response = restTemplate.getForObject(
    "http://user-service/api/users/123",
    String.class
);
```

**Method 2: Direct URL**
```java
// Direct call (less flexible)
String response = restTemplate.getForObject(
    "http://user-service:8084/api/users/123",
    String.class
);
```

## 🚀 Testing Your Services

### Check if a service is running:
```bash
# From within VPC
curl http://api-gateway:8080/actuator/health
curl http://user-service:8084/actuator/health
curl http://discovery-server:8082/eureka/apps
```

### Check service registration:
```bash
# View all registered services in Eureka
curl http://discovery-server:8082/eureka/apps
```

## ⚠️ Common Issues & Solutions

### Issue: Service can't connect to database
**Check:**
1. Database endpoint correct?
2. Security group allows connection?
3. Credentials correct?

### Issue: Services can't find each other
**Check:**
1. Is Discovery Server running?
2. Are services registered? (Check Eureka dashboard)
3. Are services in the same VPC?

### Issue: API Gateway returns 503
**Check:**
1. Are backend services healthy?
2. Check service logs in CloudWatch
3. Verify target service is registered

## 📚 Additional Resources

- **Spring Cloud Config:** https://spring.io/projects/spring-cloud-config
- **Eureka (Service Discovery):** https://spring.io/projects/spring-cloud-netflix
- **Spring Cloud Gateway:** https://spring.io/projects/spring-cloud-gateway

## 💡 Pro Tips

1. **Always start Config Server first!**
2. **Use health check endpoints:** `/actuator/health`
3. **Monitor Eureka dashboard:** `http://<discovery-server>:8082`
4. **Check CloudWatch logs** for each service
5. **Use AWS Secrets Manager** for credentials (already configured)

---

**Quick Command Reference:**

```bash
# Get all infrastructure outputs
cd infrastructure/envs/dev
terraform output

# View specific output
terraform output rds_endpoint
terraform output ecr_repository_urls

# Check ECS service status
aws ecs list-services --cluster sdt-dev-cluster

# View service logs
aws logs tail /ecs/sdt/dev/user-service --follow
```
