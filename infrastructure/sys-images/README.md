# Skills Development Tracker - System Architecture Diagrams

This directory contains high-level AWS architectural diagrams for the Skills Development Tracker (SDT) infrastructure, generated based on the Terraform infrastructure code analysis.

## 📊 Available Diagrams

### 1. SDT AWS Architecture (`sdt-aws-architecture.png`)
**Complete high-level AWS architecture overview**

Shows the complete system architecture including:
- **Frontend**: AWS Amplify hosting Angular application with CloudFront CDN
- **Networking**: VPC with public/private subnets across 2 AZs, NAT Gateways, ALB
- **Compute**: ECS Fargate cluster with 11 microservices + 3 data services
- **Databases**: RDS PostgreSQL (5 databases) + MongoDB (4 databases)
- **Storage**: ECR, S3 buckets, EFS for persistent storage
- **Security**: IAM roles, Secrets Manager
- **Monitoring**: CloudWatch logs, metrics, and alarms
- **API Management**: API Gateway service integration

### 2. SDT Network Architecture (`sdt-network-architecture.png`)
**Detailed VPC and networking design**

Focuses on network topology:
- **VPC Structure**: 10.x.0.0/16 CIDR with multi-AZ deployment
- **Subnets**: Public (10.x.1.0/24, 10.x.2.0/24) and Private (10.x.10.0/24, 10.x.11.0/24)
- **Routing**: Internet Gateway, NAT Gateways, Route Tables
- **Security Groups**: ALB, ECS, Data Services, RDS security groups
- **Service Distribution**: Services distributed across availability zones
- **Database Placement**: RDS Multi-AZ with primary/standby configuration

### 3. SDT Microservices Architecture (`sdt-microservices-architecture.png`)
**Microservices interaction and data flow**

Details the 11-service microservices architecture:

**Infrastructure Services:**
- API Gateway (:8080) - Entry point and routing
- Config Server (:8081) - Centralized configuration
- Discovery Server (:8082) - Service registry (Eureka)

**Core Business Services:**
- BFF Service (:8083) - Backend for Frontend
- User Service (:8084) - User management
- Task Service (:8085) - Task/assignment management

**Supporting Services:**
- Analytics Service (:8086) - Analytics and reporting
- Payment Service (:8087) - Payment processing
- Gamification Service (:8088) - Badges, points, achievements
- Practice Service (:8089) - Practice exercises
- Feedback Service (:8090) - Feedback and reviews
- Notification Service (:8091) - Email, SMS, push notifications

**Data Layer:**
- **PostgreSQL**: 5 databases (User, Task, Feedback, Payment, Practice)
- **MongoDB**: 4 databases (Task, Analytics, Gamification, Notification)
- **Redis**: Caching layer
- **RabbitMQ**: Message queue for notifications

### 4. SDT Deployment Architecture (`sdt-deployment-architecture.png`)
**CI/CD pipeline and deployment flow**

Shows the complete deployment pipeline:
- **Source Control**: GitHub repository
- **CI/CD**: GitHub Actions with AWS CodeBuild
- **Container Registry**: ECR repositories for each service
- **Infrastructure**: Terraform with S3 backend
- **Environments**: Dev, Staging, Production with separate clusters
- **Frontend Deployment**: AWS Amplify for each environment
- **Monitoring**: CloudWatch integration across all environments
- **Security**: Secrets Manager, IAM roles, Parameter Store

## 🏗️ Infrastructure Summary

Based on the Terraform code analysis, the infrastructure includes:

### Core Components
- **11 Microservices** (Java/Spring Boot) running on ECS Fargate
- **3 Data Services** (MongoDB, Redis, RabbitMQ) containerized on ECS
- **1 Angular Frontend** hosted on AWS Amplify
- **Multi-database architecture** with PostgreSQL and MongoDB
- **Multi-environment setup** (dev, staging, production)

### AWS Services Used
- **Compute**: ECS Fargate, AWS Lambda (potential)
- **Networking**: VPC, ALB, NAT Gateway, Route 53 (optional)
- **Database**: RDS PostgreSQL (Multi-AZ), DocumentDB (MongoDB-compatible)
- **Storage**: S3, EFS, ECR
- **Security**: IAM, Secrets Manager, Security Groups
- **Monitoring**: CloudWatch, CloudWatch Alarms
- **Frontend**: AWS Amplify, CloudFront
- **API**: API Gateway service integration

### Key Features
- **High Availability**: Multi-AZ deployment with auto-scaling
- **Security**: Private subnets, encryption at rest/transit, IAM roles
- **Scalability**: Auto-scaling ECS services, managed databases
- **Monitoring**: Comprehensive CloudWatch integration
- **CI/CD Ready**: ECR repositories and deployment automation
- **Cost Optimized**: Environment-specific resource sizing

## 📋 Port Mapping Reference

### Backend Services
```
API Gateway:         8080  (Entry point)
Config Server:       8081  (Configuration)
Discovery Server:    8082  (Service registry)
BFF Service:         8083  (Backend for Frontend)
User Service:        8084  (User management)
Task Service:        8085  (Task management)
Analytics Service:   8086  (Analytics)
Payment Service:     8087  (Payments)
Gamification:        8088  (Badges/Points)
Practice Service:    8089  (Practice exercises)
Feedback Service:    8090  (Feedback)
Notification:        8091  (Notifications)
```

### Database Ports
```
PostgreSQL:          5432-5436 (5 databases)
MongoDB:             27017-27020 (4 databases)
Redis:               6379
RabbitMQ:            5672 (AMQP), 15672 (Management)
```

## 🔄 Service Dependencies

**Startup Order:**
1. Config Server (8081) - Provides configuration
2. Discovery Server (8082) - Service registry
3. API Gateway (8080) - Request routing
4. All other services (8083-8091) - Business logic

## 💰 Cost Perspective & Optimization

### Monthly Cost Estimates (US East 1)

#### Development Environment
```
ECS Fargate (14 services):     ~$180-220/month
  - 14 tasks × 0.25 vCPU × 0.5 GB RAM × 24/7
RDS PostgreSQL (db.t3.micro):  ~$15-20/month
DocumentDB (t3.medium):        ~$65-80/month
ALB:                          ~$20-25/month
NAT Gateway (1):              ~$45-50/month
S3 Storage (100GB):           ~$2-5/month
EFS Storage (50GB):           ~$15-20/month
CloudWatch Logs:              ~$10-15/month
Amplify Hosting:              ~$1-5/month
ECR Storage:                  ~$5-10/month

TOTAL DEV:                    ~$358-455/month
```

#### Staging Environment
```
ECS Fargate (14 services):     ~$280-350/month
  - 14 tasks × 0.5 vCPU × 1 GB RAM × 24/7
RDS PostgreSQL (db.t3.small):  ~$30-40/month
DocumentDB (t3.medium):        ~$65-80/month
ALB:                          ~$20-25/month
NAT Gateway (1):              ~$45-50/month
S3 Storage (200GB):           ~$5-10/month
EFS Storage (100GB):          ~$30-35/month
CloudWatch Logs:              ~$15-25/month
Amplify Hosting:              ~$5-10/month

TOTAL STAGING:                ~$495-625/month
```

#### Production Environment
```
ECS Fargate (14 services):     ~$450-600/month
  - 14 tasks × 1 vCPU × 2 GB RAM × 24/7
  - Auto-scaling 2-8 tasks per service
RDS PostgreSQL (db.r5.large): ~$180-220/month
  - Multi-AZ deployment
DocumentDB (r5.large):         ~$280-350/month
  - 3-node cluster with replica
ALB:                          ~$25-30/month
NAT Gateway (2):              ~$90-100/month
S3 Storage (1TB):             ~$25-30/month
EFS Storage (500GB):          ~$150-175/month
CloudWatch Logs/Metrics:      ~$50-75/month
Amplify Hosting:              ~$10-20/month
Backup & Snapshots:           ~$30-50/month

TOTAL PRODUCTION:             ~$1,290-1,650/month
```

### Cost Optimization Strategies

#### Immediate Savings (0-30 days)
- **Reserved Instances**: 30-60% savings on RDS
- **Fargate Spot**: 50-70% savings for non-critical services
- **S3 Intelligent Tiering**: 20-40% storage savings
- **CloudWatch Log Retention**: Reduce from 30 to 7 days in dev

#### Medium-term Savings (1-6 months)
- **Right-sizing**: Monitor and adjust ECS task resources
- **Scheduled Scaling**: Scale down dev/staging during off-hours
- **Data Lifecycle**: Archive old data to Glacier
- **Unused Resources**: Regular cleanup of orphaned resources

#### Long-term Savings (6+ months)
- **Savings Plans**: 20-72% discount on compute
- **Multi-AZ Optimization**: Single AZ for dev/staging
- **Service Consolidation**: Combine low-traffic services
- **CDN Implementation**: Reduce data transfer costs

### Cost Monitoring & Alerts

**Recommended CloudWatch Billing Alarms:**
- Dev Environment: >$500/month
- Staging Environment: >$700/month  
- Production Environment: >$2,000/month
- Total Account: >$3,000/month

**Cost Allocation Tags:**
```
Environment: dev|staging|production
Project: skills-development-tracker
Service: api-gateway|user-service|etc
Owner: team-name
CostCenter: engineering
```

### Environment-Specific Cost Controls

#### Development
- **Single NAT Gateway** (vs 2 in production)
- **No Multi-AZ RDS** (single instance)
- **Smaller instance types** (t3.micro/small)
- **Reduced backup retention** (7 days vs 30)
- **No read replicas**

#### Staging  
- **Performance testing budget** (~20% higher than dev)
- **Enhanced monitoring** for performance insights
- **Automated shutdown** during weekends

#### Production
- **High availability** (Multi-AZ, auto-scaling)
- **Enhanced backup** (30-day retention, cross-region)
- **Performance Insights** enabled
- **Reserved capacity** for predictable workloads

## 📚 Related Documentation

- [ARCHITECTURE.md](../ARCHITECTURE.md) - Detailed technical architecture
- [SERVICE_PORTS_REFERENCE.md](../SERVICE_PORTS_REFERENCE.md) - Complete port mapping
- [README.md](../README.md) - Infrastructure setup and usage
- [DEPLOYMENT_CHECKLIST.md](../DEPLOYMENT_CHECKLIST.md) - Deployment procedures

## 🎯 Diagram Usage

These diagrams are designed for:
- **Architecture Reviews** - Understanding system design
- **Documentation** - Technical documentation and presentations
- **Onboarding** - New team member orientation
- **Planning** - Infrastructure changes and scaling decisions
- **Troubleshooting** - Understanding service interactions and dependencies

---

**Generated on:** October 17, 2025  
**Based on:** Terraform infrastructure code analysis  
**Tool:** AWS Architecture Diagrams using Python diagrams library
