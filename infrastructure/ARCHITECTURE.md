# SDT Infrastructure Architecture

## Overview

The Skills Development Tracker (SDT) infrastructure is built on AWS using a modern, scalable microservices architecture with infrastructure-as-code principles.

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
