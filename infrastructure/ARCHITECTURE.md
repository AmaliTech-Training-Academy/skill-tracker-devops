# SDT Infrastructure Architecture

## Overview

The Skills Development Tracker (SDT) infrastructure is built on AWS using a modern, scalable microservices architecture with infrastructure-as-code principles.

## Architectural Decision Reasoning

This section documents the key architectural decisions and the rationale behind them, following the AWS Well-Architected Framework principles.

### 1. Why Microservices Architecture?

**Decision**: Implement 11+ independent microservices instead of a monolithic application.

**Reasoning**:
- **Independent Scaling**: Each service (user, task, payment, etc.) can scale independently based on its specific load patterns
- **Team Autonomy**: Multiple development teams can work on different services without blocking each other
- **Technology Flexibility**: Services can use different databases (PostgreSQL, MongoDB) based on their data requirements
- **Fault Isolation**: Failure in one service (e.g., notification) doesn't bring down critical services (e.g., user authentication)
- **Faster Deployments**: Deploy individual services without redeploying the entire application

**Trade-offs**:
- Increased operational complexity (managed through automation and IaC)
- Network latency between services (mitigated by service discovery and same-VPC deployment)
- Distributed transaction challenges (addressed through eventual consistency patterns)

### 2. Why AWS ECS Fargate?

**Decision**: Use ECS Fargate instead of EC2-based ECS, EKS, or traditional VMs.

**Reasoning**:
- **Serverless Compute**: No server management, patching, or capacity planning
- **Cost Efficiency**: Pay only for container runtime (no idle EC2 instances in dev)
- **Faster Onboarding**: Simpler than Kubernetes for teams new to container orchestration
- **AWS Integration**: Native integration with ALB, CloudWatch, Secrets Manager, ECR
- **Auto-scaling**: Built-in task-level auto-scaling based on CPU/Memory metrics

**Why Not EKS?**:
- Kubernetes adds complexity for a team learning DevOps
- ECS Fargate provides sufficient orchestration for current needs
- Lower operational overhead (no control plane management)
- Can migrate to EKS later if advanced features needed

**Why Not EC2?**:
- No need to manage OS patches, security updates
- Better resource utilization (no over-provisioning)
- Faster scaling response times

### 3. Why Multi-AZ Deployment?

**Decision**: Deploy resources across 2 availability zones (eu-west-1a, eu-west-1b).

**Reasoning**:
- **High Availability**: Survive single AZ failure (99.99% vs 99.9% SLA)
- **Zero-Downtime Deployments**: Rolling updates across AZs
- **Load Distribution**: Spread traffic and reduce latency
- **AWS Best Practice**: Recommended for production workloads

**Cost Consideration**:
- Dev: Single NAT Gateway option to reduce costs
- Production: Dual NAT Gateways for true HA

### 4. Why Private Subnets for Application Tier?

**Decision**: Run all ECS tasks and databases in private subnets with no direct internet access.

**Reasoning**:
- **Security**: Reduces attack surface (no direct internet exposure)
- **Compliance**: Meets security requirements for handling user data
- **Defense in Depth**: Multiple layers of security (ALB → Private subnet → Security groups)
- **Controlled Egress**: All outbound traffic through NAT Gateway (auditable)

**Implementation**:
- Public subnets: ALB and NAT Gateways only
- Private subnets: ECS tasks, RDS, EFS, data services

### 5. Why Spring Cloud Config + Eureka?

**Decision**: Use Spring Cloud Config Server (8081) and Eureka Discovery Server (8082).

**Reasoning**:
- **Centralized Configuration**: Single source of truth for all service configs
- **Dynamic Updates**: Change configs without redeploying services
- **Service Discovery**: Services find each other by name (not hardcoded IPs)
- **Load Balancing**: Client-side load balancing through Eureka
- **Spring Ecosystem**: Native integration with Spring Boot microservices

**Startup Order Dependency**:
1. Config Server must start first (provides configs to all services)
2. Discovery Server second (registers all services)
3. API Gateway third (routes to registered services)
4. Other services can start in parallel

**Critical Learning** (from memory):
- Local Docker uses service names; AWS ECS uses Service Discovery DNS
- Environment variables must be properly configured in ECS task definitions
- Health checks removed in ECS due to curl unavailability in containers

### 6. Why Polyglot Persistence (PostgreSQL + MongoDB)?

**Decision**: Use both PostgreSQL and MongoDB instead of a single database.

**Reasoning**:
- **Right Tool for the Job**:
  - PostgreSQL: Transactional data (users, payments, tasks) requiring ACID guarantees
  - MongoDB: Flexible schemas (analytics, notifications, gamification) with high write throughput
- **Performance Optimization**: Each service uses the database that fits its access patterns
- **Scalability**: MongoDB handles high-volume, schema-less data better

**Service-Database Mapping**:
- PostgreSQL: user-service, payment-service, practice-service, feedback-service, task-service
- MongoDB: analytics-service, gamification-service, notification-service, task-service (dual)
- Task-service uses both: PostgreSQL for task metadata, MongoDB for task submissions/results

### 7. Why EFS for Data Services?

**Decision**: Use EFS (Elastic File System) for MongoDB, Redis, and RabbitMQ persistence.

**Reasoning**:
- **Shared Storage**: Multiple ECS tasks can mount the same file system
- **Persistence**: Data survives container restarts and redeployments
- **Automatic Scaling**: Storage grows automatically (no capacity planning)
- **Multi-AZ**: Data replicated across availability zones
- **Cost-Effective**: Pay only for storage used (vs provisioned EBS volumes)

**Alternative Considered**:
- Managed services (DocumentDB, ElastiCache, Amazon MQ) were too expensive for dev/staging
- EFS provides good balance of cost and functionality for non-production environments

### 8. Why AWS Amplify for Frontend?

**Decision**: Use AWS Amplify instead of S3 + CloudFront or self-hosted.

**Reasoning**:
- **Simplified CI/CD**: Auto-deploy on git push (no pipeline configuration needed)
- **Built-in CDN**: CloudFront distribution included
- **Branch Previews**: Automatic preview environments for feature branches
- **Framework Support**: Native Angular support with optimized builds
- **SSL/TLS**: Automatic HTTPS certificates
- **Cost**: Free tier covers dev usage; pay-as-you-go for production

**Configuration**:
- Custom build spec to handle Angular routing (_redirects file)
- Environment variables injected at build time (API Gateway URL)

### 9. Why API Gateway (AWS Service) + API Gateway (Microservice)?

**Decision**: Use both AWS API Gateway service and a custom API Gateway microservice.

**Reasoning**:
- **AWS API Gateway**: Provides managed REST API endpoint, throttling, API keys, usage plans
- **Spring Cloud Gateway (Microservice)**: Routes requests to internal microservices, handles authentication, rate limiting

**Flow**:
```
Internet → AWS API Gateway → ALB → API Gateway Microservice (8080) → Internal Services
```

**Benefits**:
- AWS API Gateway: DDoS protection, caching, request validation
- Spring Cloud Gateway: Business logic routing, service discovery integration, custom filters

### 10. Why Infrastructure as Code (Terraform)?

**Decision**: Use Terraform instead of CloudFormation or manual console configuration.

**Reasoning**:
- **Reproducibility**: Identical environments (dev, staging, prod) with different parameters
- **Version Control**: Infrastructure changes tracked in Git
- **Modularity**: Reusable modules (networking, ECS, RDS, etc.)
- **Multi-Cloud**: Terraform skills transferable to other cloud providers
- **State Management**: Remote state in S3 with DynamoDB locking prevents conflicts
- **Collaboration**: Multiple team members can work on infrastructure safely

**Module Structure**:
- `modules/`: Reusable components
- `envs/`: Environment-specific configurations
- Clear separation of concerns

### 11. Why Separate VPCs per Environment?

**Decision**: Use different VPC CIDR blocks for dev (10.0.0.0/16), staging (10.1.0.0/16), production (10.2.0.0/16).

**Reasoning**:
- **Isolation**: Complete network isolation between environments
- **Security**: Production breach doesn't affect dev/staging
- **Independent Changes**: Test network changes in dev without production risk
- **Compliance**: Separate environments for audit purposes
- **VPC Peering Ready**: Can peer VPCs if needed for data migration

### 12. Why Auto-Scaling with Conservative Targets?

**Decision**: Auto-scale at 70-80% CPU/Memory utilization with 60s scale-out, 300s scale-in cooldowns.

**Reasoning**:
- **Performance Buffer**: 70-80% target leaves headroom for traffic spikes
- **Cost Efficiency**: Not over-provisioning (vs 50% target)
- **Fast Scale-Out**: 60s cooldown responds quickly to load increases
- **Slow Scale-In**: 300s cooldown prevents flapping (rapid scale up/down)
- **Predictable Costs**: Min/max capacity limits prevent runaway scaling

**Environment-Specific**:
- Dev: 1-2 tasks (cost optimization)
- Staging: 1-4 tasks (testing scale behavior)
- Production: 2-8 tasks (HA + performance)

### 13. Why AWS Secrets Manager over Parameter Store?

**Decision**: Use Secrets Manager for database credentials instead of Systems Manager Parameter Store.

**Reasoning**:
- **Automatic Rotation**: Built-in rotation for RDS credentials
- **Encryption**: Automatic encryption at rest with KMS
- **Versioning**: Track secret changes over time
- **Cross-Region Replication**: Ready for multi-region DR
- **Audit Trail**: CloudTrail logs all secret access

**Cost Trade-off**:
- Secrets Manager: $0.40/secret/month + $0.05/10,000 API calls
- Parameter Store: Free for standard, $0.05/advanced parameter
- Worth the cost for automatic rotation and better security

### 14. Why CloudWatch over Third-Party Monitoring?

**Decision**: Use CloudWatch for logs, metrics, and alarms instead of Datadog, New Relic, etc.

**Reasoning**:
- **Native Integration**: Zero configuration for ECS, RDS, ALB metrics
- **Cost**: Included in AWS usage (no additional vendor fees for dev)
- **Simplicity**: One less tool to learn and manage
- **Container Insights**: Deep ECS/Fargate visibility
- **Alarms**: Direct integration with SNS for notifications

**Future Enhancement**:
- Can add third-party APM (Application Performance Monitoring) later if needed
- CloudWatch provides sufficient observability for current scale

### 15. Why This Security Model?

**Decision**: Defense-in-depth with multiple security layers.

**Reasoning**:
- **Network Layer**: Private subnets, security groups, NACLs
- **Application Layer**: IAM roles with least privilege
- **Data Layer**: Encryption at rest (S3, RDS, EFS) and in transit (TLS)
- **Secrets Layer**: No hardcoded credentials (Secrets Manager)
- **Audit Layer**: CloudTrail, VPC Flow Logs (staging/prod)

**Principle of Least Privilege**:
- ECS Task Execution Role: Only pull images, write logs
- ECS Task Role: Only access required S3 buckets, secrets
- Security Groups: Only allow required ports between services

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Internet                                    │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   Route 53      │
                    │   (Optional)    │
                    └────────┬────────┘
                             │
                ┌────────────┴──────────────┐
                │                           │
                ▼                           ▼
        ┌───────────────┐          ┌──────────────┐
        │  AWS Amplify  │          │     ALB      │
        │  (Frontend)   │          │  (Backend)   │
        └───────────────┘          └──────┬───────┘
                                           │
┌──────────────────────────────────────────┼──────────────────────────────┐
│  VPC (10.x.0.0/16)                       │                              │
│                                          │                              │
│  ┌──────────────────────────┬───────────┴────┬──────────────────────┐  │
│  │  Public Subnet 1         │  Public Subnet 2 │                     │  │
│  │  (10.x.1.0/24)           │  (10.x.2.0/24)   │                     │  │
│  │  AZ: us-east-1a          │  AZ: us-east-1b  │                     │  │
│  │                          │                  │                     │  │
│  │  ┌──────────┐            │  ┌──────────┐   │                     │  │
│  │  │   NAT    │            │  │   NAT    │   │                     │  │
│  │  │ Gateway  │            │  │ Gateway  │   │                     │  │
│  │  └────┬─────┘            │  └────┬─────┘   │                     │  │
│  └───────┼──────────────────┴───────┼─────────┘                     │  │
│          │                          │                                │  │
│  ┌───────┼──────────────────────────┼─────────────────────────────┐ │  │
│  │       │  Private Subnet 1        │  Private Subnet 2           │ │  │
│  │       │  (10.x.10.0/24)          │  (10.x.11.0/24)             │ │  │
│  │       │  AZ: us-east-1a          │  AZ: us-east-1b             │ │  │
│  │       │                          │                             │ │  │
│  │  ┌────▼──────────────┐      ┌───▼──────────────┐              │ │  │
│  │  │                   │      │                  │              │ │  │
│  │  │  ECS Fargate      │      │  ECS Fargate     │              │ │  │
│  │  │  Tasks            │      │  Tasks           │              │ │  │
│  │  │                   │      │                  │              │ │  │
│  │  │  ┌──────────────┐ │      │  ┌──────────────┐│              │ │  │
│  │  │  │auth-service  │ │      │  │auth-service  ││              │ │  │
│  │  │  └──────────────┘ │      │  └──────────────┘│              │ │  │
│  │  │  ┌──────────────┐ │      │  ┌──────────────┐│              │ │  │
│  │  │  │content-svc   │ │      │  │content-svc   ││              │ │  │
│  │  │  └──────────────┘ │      │  └──────────────┘│              │ │  │
│  │  │  ┌──────────────┐ │      │  ┌──────────────┐│              │ │  │
│  │  │  │submission-svc│ │      │  │submission-svc││              │ │  │
│  │  │  └──────────────┘ │      │  └──────────────┘│              │ │  │
│  │  │  ┌──────────────┐ │      │  ┌──────────────┐│              │ │  │
│  │  │  │sandbox-runner│ │      │  │sandbox-runner││              │ │  │
│  │  │  └──────────────┘ │      │  └──────────────┘│              │ │  │
│  │  │                   │      │                  │              │ │  │
│  │  └───────────────────┘      └──────────────────┘              │ │  │
│  │            │                          │                        │ │  │
│  │            └──────────┬───────────────┘                        │ │  │
│  │                       │                                        │ │  │
│  │                       ▼                                        │ │  │
│  │              ┌─────────────────┐                               │ │  │
│  │              │   RDS           │                               │ │  │
│  │              │   PostgreSQL    │                               │ │  │
│  │              │   (Multi-AZ)    │                               │ │  │
│  │              └─────────────────┘                               │ │  │
│  │                                                                │ │  │
│  └────────────────────────────────────────────────────────────────┘ │  │
│                                                                      │  │
└──────────────────────────────────────────────────────────────────────┘  │
                                                                           │
┌────────────────────────────────────────────────────────────────────────┤
│  Supporting Services                                                   │
│                                                                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐         │
│  │   ECR    │  │    S3    │  │CloudWatch│  │AWS Secrets   │         │
│  │Container │  │ Buckets  │  │Logs/Alarms│ │  Manager     │         │
│  │Registry  │  │          │  │           │  │              │         │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘         │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Networking Layer

#### VPC (Virtual Private Cloud)
- **CIDR Blocks**:
  - Dev: 10.0.0.0/16
  - Staging: 10.1.0.0/16
  - Production: 10.2.0.0/16
- **Multi-AZ**: Resources deployed across 2 availability zones
- **DNS**: Enabled for service discovery

#### Subnets
- **Public Subnets (2)**:
  - Used for: ALB, NAT Gateways
  - Internet access via Internet Gateway
  - Each in different AZ for HA
  
- **Private Subnets (2)**:
  - Used for: ECS tasks, RDS instances
  - Internet access via NAT Gateway (if enabled)
  - Isolated from direct internet access

#### Network Security
- **Security Groups**: Restrictive ingress/egress rules
- **NACLs**: Default AWS NACLs
- **VPC Flow Logs**: Enabled in staging/production

### 2. Compute Layer

#### ECS (Elastic Container Service)
- **Launch Type**: Fargate (serverless)
- **Cluster**: One per environment
- **Services**: 4 microservices
  - auth-service
  - content-service
  - submission-service
  - sandbox-runner

#### Auto-Scaling
- **Metrics**: CPU and Memory utilization
- **Target**: 70-80% utilization
- **Scaling Policies**:
  - Scale out: 60 seconds cooldown
  - Scale in: 300 seconds cooldown

#### Service Configuration
| Environment | Min Tasks | Max Tasks |
|-------------|-----------|-----------|
| Dev         | 1         | 2-3       |
| Staging     | 1         | 4-5       |
| Production  | 2         | 8-10      |

### 3. Data Layer

#### RDS PostgreSQL
- **Engine**: PostgreSQL 15.4
- **Deployment**: Private subnets only
- **Encryption**: At rest (AES-256)
- **Backups**: Automated daily backups
- **Multi-AZ**: Production only
- **Read Replicas**: Production only

| Environment | Instance Class | Storage | Backups | Multi-AZ |
|-------------|---------------|---------|---------|----------|
| Dev         | db.t3.micro   | 20 GB   | 7 days  | No       |
| Staging     | db.t3.small   | 50 GB   | 14 days | No       |
| Production  | db.r5.large   | 100 GB  | 30 days | Yes      |

#### Secrets Management
- **Service**: AWS Secrets Manager
- **Rotation**: Supported (manual)
- **Access**: Via IAM roles only

### 4. Storage Layer

#### S3 Buckets
1. **User Uploads**
   - Versioning: Enabled
   - Encryption: AES-256
   - Lifecycle: Archive to Glacier after 90 days
   - CORS: Enabled

2. **Static Assets**
   - Versioning: Enabled
   - CDN: Optional CloudFront
   - Public access: Blocked

3. **Application Logs**
   - Lifecycle: Archive after 30 days, delete after retention period
   - Encryption: AES-256

4. **Terraform State** (if created)
   - Versioning: Enabled
   - Encryption: AES-256
   - Locking: DynamoDB

### 5. Container Registry

#### ECR (Elastic Container Registry)
- **Repositories**: One per service
- **Scanning**: Enabled on push
- **Lifecycle**: Keep last 10 tagged images
- **Encryption**: AES-256

### 6. Load Balancing

#### Application Load Balancer
- **Type**: Application (Layer 7)
- **Scheme**: Internet-facing
- **Subnets**: Public subnets
- **Health Checks**: HTTP /health endpoint
- **SSL/TLS**: Configurable (not in base config)

### 7. Frontend Hosting

#### AWS Amplify
- **Source**: Git repository (GitHub/GitLab/etc)
- **Build**: Automatic on git push
- **Framework**: Angular
- **CDN**: Built-in CloudFront distribution
- **Branch Deployments**: Enabled for dev

### 8. Monitoring & Observability

#### CloudWatch
- **Metrics**: Standard + Container Insights
- **Log Groups**: Per service
- **Retention**: 30-90 days
- **Dashboards**: ECS and RDS dashboards

#### Alarms
- ECS: CPU/Memory thresholds
- RDS: CPU/Storage/Connections
- ALB: Unhealthy targets, 5XX errors, response time

#### Optional Features
- **X-Ray**: Distributed tracing (staging/production)
- **VPC Flow Logs**: Network traffic analysis (staging/production)

### 9. Security

#### IAM Roles & Policies
- **ECS Task Execution Role**: Pull images, write logs
- **ECS Task Role**: Application permissions (S3, Secrets Manager)
- **Amplify Role**: Build and deploy frontend
- **Monitoring Role**: Enhanced RDS monitoring

#### Network Security
- **Private Subnets**: No direct internet access
- **Security Groups**: Least privilege
- **Encryption**: At rest and in transit
- **Secrets**: Stored in AWS Secrets Manager

## Data Flow

### Request Flow (Backend)
1. User request → Route53 (optional) → ALB
2. ALB → ECS Service (target group)
3. ECS Task processes request
4. ECS Task → RDS (database query)
5. ECS Task → S3 (file operations)
6. Response back through ALB

### Request Flow (Frontend)
1. User request → Amplify CloudFront distribution
2. CloudFront → S3 (static assets)
3. Browser → ALB (API calls)

### Deployment Flow
1. Code pushed to Git repository
2. CI/CD builds Docker image
3. Image pushed to ECR
4. ECS service updated with new task definition
5. ECS performs rolling deployment

## High Availability

### Multi-AZ Deployment
- **ALB**: Deployed across 2 AZs
- **NAT Gateways**: One per AZ (production)
- **ECS Tasks**: Distributed across AZs
- **RDS**: Multi-AZ with automatic failover (production)

### Failure Scenarios

| Component | Failure | Recovery |
|-----------|---------|----------|
| AZ Failure | Traffic routed to healthy AZ | Automatic |
| ECS Task | Health check fails → terminate & restart | Automatic |
| RDS Primary | Failover to standby (Multi-AZ) | ~60 seconds |
| NAT Gateway | Traffic routed to other AZ | Automatic |

## Scalability

### Horizontal Scaling
- **ECS**: Auto-scaling based on CPU/Memory
- **RDS**: Read replicas for read-heavy workloads
- **S3**: Unlimited scalability

### Vertical Scaling
- **ECS**: Adjust task CPU/Memory
- **RDS**: Change instance class (requires downtime)

## Cost Optimization

### Development
- Single NAT Gateway or none
- Smaller RDS instances
- Shorter log retention
- No Multi-AZ
- No read replicas

### Production
- Cost optimization features:
  - ECS Fargate Spot for non-critical tasks
  - S3 Intelligent-Tiering
  - CloudWatch log retention policies
  - RDS Reserved Instances

## Disaster Recovery

### Backup Strategy
- **RDS**: Automated daily backups
- **S3**: Versioning enabled
- **Terraform State**: Versioned in S3

### Recovery Time Objective (RTO)
- Dev: 4-8 hours
- Staging: 2-4 hours
- Production: 1 hour

### Recovery Point Objective (RPO)
- Dev: 24 hours
- Staging: 12 hours
- Production: 1 hour (point-in-time recovery)

## Performance Considerations

### Latency
- **ALB → ECS**: < 10ms (same region)
- **ECS → RDS**: < 5ms (same VPC)
- **ECS → S3**: < 20ms (same region)

### Throughput
- **ALB**: Scales automatically
- **ECS**: Based on task count and resources
- **RDS**: Based on instance class
- **S3**: 3,500 PUT/COPY/POST/DELETE and 5,500 GET/HEAD requests per second per prefix

## Future Enhancements

1. **CDN**: CloudFront for static assets
2. **WAF**: Web Application Firewall
3. **ElastiCache**: Redis for caching
4. **Service Mesh**: AWS App Mesh for advanced routing
5. **CI/CD**: Full GitHub Actions/GitLab CI integration
6. **Secrets Rotation**: Automated secret rotation
7. **Multi-Region**: DR setup in another region
8. **Container Insights**: Advanced ECS monitoring

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
