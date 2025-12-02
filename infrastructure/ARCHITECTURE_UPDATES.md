# ARCHITECTURE.md Updates Summary

## Changes Made to Reflect Dev Environment Reality

### Updated Architecture Diagram

The diagram now accurately shows:

1. **Subnet Attachments**:
   - **Public Subnets (10.0.1.0/24, 10.0.2.0/24)**:
     - Application Load Balancer (ALB) - spans both AZs
     - NAT Gateway - in subnet 1 only (dev cost optimization)
     - EC2 Observability instance - in subnet 1 (Prometheus + Grafana)

   - **Private Subnets (10.0.10.0/24, 10.0.11.0/24)**:
     - All 12 microservices (distributed across both AZs)
     - All 3 data services: MongoDB, Redis, RabbitMQ (in private subnets)
     - RDS PostgreSQL primary (in private subnets)

2. **Complete Service List**:
   - Previously showed 4 services (auth, content, submission, sandbox)
   - Now shows all 12 actual services:
     - Infrastructure: config-server:8081, discovery-server:8082, api-gateway:8080, bff-service:8083
     - Business: user-service:8084, task-service:8085, analytics-service:8086, payment-service:8087, gamification-service:8088, practice-service:8089, feedback-service:8090, notification-service:8091

3. **Data Services Architecture**:
   - Clarified that MongoDB, Redis, RabbitMQ run as ECS Fargate tasks (not managed services)
   - All run in private subnets for security
   - RabbitMQ has ALB target group for management console access

4. **Request Flow**:
   - Added CloudFront for SSL termination
   - Shows complete flow: Internet → CloudFront → AWS API Gateway → ALB → api-gateway:8080 → services
   - Service discovery flow via discovery-server:8082 and CloudMap

5. **Region Correction**:
   - Changed from eu-west-1 to us-east-1 (actual deployment region)
   - Changed AZs from eu-west-1a/b to us-east-1a/b

6. **Observability Stack**:
   - Added EC2-based Prometheus + Grafana in public subnet
   - Shows ADOT sidecar containers on port 8889
   - Prometheus scrapes ECS tasks via service discovery

### Updated Component Descriptions

1. **Compute Layer**:
   - Listed all 12 microservices with their ports and purposes
   - Added data services section showing they run on ECS Fargate
   - Clarified service startup dependencies

2. **Networking Layer**:
   - Specified exact CIDR blocks for dev environment
   - Clarified NAT Gateway is single instance in dev (cost optimization)
   - Listed specific resources in each subnet type

3. **Monitoring & Observability**:
   - Added detailed Prometheus + Grafana section
   - Explained ADOT sidecar pattern for metrics collection
   - Clarified EC2 deployment in public subnet with public IP access

4. **Architectural Decisions**:
   - Updated "Why EFS for Data Services?" to "Why Self-Hosted Data Services on ECS?"
   - Explained cost-driven decision to use containerized data services
   - Clarified EFS is available but not currently mounted (acceptable for dev)
   - Updated API Gateway section to include CloudFront's role

5. **Database Mapping**:
   - Updated service-to-database relationships
   - Added Redis and RabbitMQ usage patterns
   - Clarified PostgreSQL vs MongoDB use cases

### Key Infrastructure Insights

**Dev Environment Characteristics**:
- VPC: 10.0.0.0/16
- Single NAT Gateway (cost optimization)
- RDS: db.t3.micro, single-AZ
- ECS: 1-2 tasks per service
- Observability: EC2 t3.medium in public subnet
- All application workloads in private subnets

**Security Posture**:
- Zero services exposed directly to internet
- ALB is only entry point in public subnets
- Observability instance has public IP but restricted security groups
- All microservices communicate within private subnets

**Cost Optimization**:
- Self-hosted MongoDB, Redis, RabbitMQ instead of managed services
- Single NAT Gateway in dev
- Smaller RDS instance class
- ADOT for observability instead of paid APM tools

## Files Modified

1. `/infrastructure/ARCHITECTURE.md` - Comprehensive updates to diagram, component descriptions, and architectural decisions

## Validation Needed

To ensure accuracy, verify:
1. ✅ All 12 microservices are listed with correct ports
2. ✅ Data services (MongoDB, Redis, RabbitMQ) shown in private subnets
3. ✅ Observability EC2 shown in public subnet
4. ✅ ALB placement in public subnets confirmed
5. ✅ RDS placement in private subnets confirmed
6. ✅ NAT Gateway configuration (single in dev) confirmed
7. ✅ Region and AZ corrections (us-east-1a/b)

## Next Steps

Consider adding:
1. Detailed security group rules diagram
2. Service-to-service communication matrix
3. Data flow diagrams for key user journeys
4. Cost breakdown by environment
5. Disaster recovery procedures
