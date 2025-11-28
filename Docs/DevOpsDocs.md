# DevOps Documentation - Skill Tracker

## Overview

The Skill Tracker DevOps infrastructure implements comprehensive CI/CD pipelines, automated code quality analysis, infrastructure as code, and production-grade monitoring for 12 microservices deployed on AWS ECS Fargate.

## CI/CD Architecture

### Pipeline Overview

```
Developer Push → GitHub → GitHub Actions → Build → Test → SonarQube → ECR → ECS Deploy → Health Check → Slack Notification
```

### GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `backend-feature-to-dev-cicd.yml` | PR merge to `dev` | Build, test, analyze, deploy to dev |
| `backend-dev-to-staging-cicd.yml` | Manual/Automated | Promote dev to staging |
| `workflow-dispatcher.yml` | Repository dispatch | Orchestrate deployments |
| `manual-service-deploy.yml` | Manual trigger | Deploy specific services |

## Sprint 3 Achievements

### 1. Multi-Service Pipeline Expansion

**Before Sprint 3**: 3 services (auth, content, submission)
**After Sprint 3**: 15 services (12 active + 3 core services)

**Active Services Deployed**:
- **Core**: config-server, discovery-server, api-gateway
- **Business**: user-service, task-service, skill-service, assessment-service
- **Support**: analytics-service, feedback-service, notification-service, report-service
- **Integration**: recommendation-service, search-service, integration-service, collaboration-service

**Infrastructure Ready (Code Pending)**:
- bff-service, payment-service, gamification-service, practice-service

### 2. SonarQube Integration

**Implementation**:
- Dedicated SonarQube server with PostgreSQL backend
- Automated analysis on PR merge to `dev` branch
- Quality gates enforce standards before deployment
- Maven Sonar plugin integration
- Caching for SonarQube packages and Maven dependencies

**Quality Gates**:
- Code coverage > 80%
- No critical bugs
- No security vulnerabilities
- Technical debt ratio < 5%
- Duplicated code < 3%

**Workflow Integration**:
```yaml
- name: SonarQube Analysis
  run: |
    mvn clean verify sonar:sonar \
      -Dsonar.projectKey=${{ matrix.service }} \
      -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }} \
      -Dsonar.login=${{ secrets.SONAR_TOKEN }}
```

### 3. Intelligent Change Detection

**Problem**: Pipeline deployed all services even when only one changed, wasting time and money.

**Solution**: Detect changed services and deploy only those.

```yaml
- name: Detect Changed Services
  id: changes
  run: |
    CHANGED_SERVICES=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }} | \
      grep '^services/' | \
      cut -d'/' -f2 | \
      sort -u | \
      jq -R -s -c 'split("\n")[:-1]')
    echo "services=$CHANGED_SERVICES" >> $GITHUB_OUTPUT
```

**Benefits**:
- 60% reduction in unnecessary builds
- Faster deployment times
- Lower AWS costs
- Graceful handling of empty deployments

### 4. Build Dependency Resolution

**Challenges Encountered**:

1. **Maven Module Path Error**:
   - Error: "Could not find the selected project in the reactor: common-security"
   - Fix: Updated paths to `skilltracker-common/common-security`

2. **Build Order Dependencies**:
   - user-service must build before task-service
   - Shared modules must build first

**Solution**:
```yaml
- name: Build Shared Dependencies
  run: |
    mvn clean install -pl skilltracker-common/common-event
    mvn clean install -pl skilltracker-common/common-security
    mvn clean install -pl skilltracker-common/common-util

- name: Build Services
  run: |
    mvn clean install -pl user-service
    mvn clean install -pl task-service  # Depends on user-service
    # ... other services
```

### 5. Image Tagging Strategy

**Problem**: ECS deployments failing with `CannotPullContainerError` for commit SHA-tagged images.

**Root Cause**: Race condition between image push and ECS deployment.

**Solution**:
- ECS task definitions use `:latest` tag
- Pipeline tags images with both `:latest` and commit SHA
- Ensures image always available for deployment
- Commit SHA tags retained for traceability

```bash
# Tag with both latest and commit SHA
docker tag $SERVICE:build $ECR_REPO:latest
docker tag $SERVICE:build $ECR_REPO:$COMMIT_SHA

# Push both tags
docker push $ECR_REPO:latest
docker push $ECR_REPO:$COMMIT_SHA
```

### 6. Enhanced Health Checks

**Improvements**:
- Health check uses only detected services (not all 12)
- Fixed null count handling
- Removed multi-line fields from Slack notifications
- Graceful failure handling

```yaml
- name: Health Check
  run: |
    for service in ${{ steps.changes.outputs.services }}; do
      HEALTH_URL="http://${ALB_DNS}/api/${service}/actuator/health"
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)
      if [ $STATUS -ne 200 ]; then
        echo "Health check failed for $service"
        exit 1
      fi
    done
```

## Pipeline Workflows

### Feature to Dev Pipeline

**Trigger**: PR merge to `dev` branch

**Steps**:
1. Checkout code
2. Detect changed services
3. Setup Java 17 and Maven
4. Build shared dependencies
5. Build changed services
6. Run unit tests
7. **SonarQube analysis** (quality gate)
8. Build Docker images
9. Push to ECR (`:latest` and `:commit-sha`)
10. Trigger DevOps deployment (repository dispatch)
11. Wait for deployment completion
12. Health check deployed services
13. Slack notification (success/failure)

**Workflow File**: `.github/workflows/backend-feature-to-dev-cicd.yml`

### Dev to Staging Pipeline

**Trigger**: Manual or automated promotion

**Steps**:
1. Checkout code
2. Verify dev deployment health
3. Pull images from dev ECR
4. Retag for staging
5. Push to staging ECR
6. Update ECS services in staging
7. Health check
8. Slack notification

**Workflow File**: `.github/workflows/backend-dev-to-staging-cicd.yml`

### Workflow Dispatcher

**Purpose**: Orchestrate deployments across environments

**Trigger**: Repository dispatch from backend repo

**Metadata Passed**:
```json
{
  "services": ["user-service", "task-service"],
  "environment": "dev",
  "commit_sha": "abc123",
  "pr_title": "Add new feature",
  "pr_author": "developer",
  "pr_url": "https://github.com/..."
}
```

**Workflow File**: `.github/workflows/workflow-dispatcher.yml`

### Manual Service Deploy

**Purpose**: Deploy specific services manually (hotfix, rollback)

**Inputs**:
- Environment (dev/staging/production)
- Service name
- Image tag (default: latest)

**Workflow File**: `.github/workflows/manual-service-deploy.yml`

## Infrastructure as Code

### Terraform Structure

```
infrastructure/
├── modules/              # Reusable modules
│   ├── networking/       # VPC, subnets, NAT
│   ├── ecs/             # ECS cluster, services
│   ├── rds/             # PostgreSQL database
│   ├── data-services/   # MongoDB, RabbitMQ, Redis
│   ├── api-gateway/     # API Gateway
│   ├── amplify/         # Frontend hosting
│   ├── cloudfront/      # CDN distribution
│   ├── monitoring/      # CloudWatch
│   ├── observability/   # Grafana, Prometheus
│   └── s3/              # S3 buckets
└── envs/                # Environment configs
    ├── dev/
    ├── staging/
    └── production/
```

### Terraform Workflow

```bash
# Initialize
cd infrastructure/envs/dev
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy (careful!)
terraform destroy
```

### State Management

- **Backend**: S3 bucket with DynamoDB locking
- **State Files**: Separate per environment
- **Encryption**: Enabled
- **Versioning**: Enabled

```hcl
terraform {
  backend "s3" {
    bucket         = "sdt-terraform-state"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "sdt-dev-locks"
  }
}
```

## Observability & Monitoring

### Grafana Dashboards

**Sprint 3 Implementation**: Complete Grafana stack with AWS CloudWatch integration

**Dashboards Created**:
1. **Service Overview** (`sdt-service-overview.json`)
   - ECS task count per service
   - CPU and memory utilization
   - Request rate and latency
   - Error rate

2. **Infrastructure Monitoring** (`sdt-infrastructure.json`)
   - VPC metrics
   - ALB metrics (requests, latency, errors)
   - RDS metrics (connections, CPU, storage)
   - ECS cluster metrics

3. **Cost Monitoring** (`sdt-cost-monitoring.json`)
   - Daily cost breakdown by service
   - Monthly cost trends
   - Cost per environment
   - Budget alerts

4. **Live Cost Monitoring** (`sdt-cost-monitoring-live.json`)
   - Real-time cost tracking
   - Cost per hour
   - Projected monthly cost

### Cost Monitoring

**Lambda Cost Exporter** (`cost_exporter.py`):
- Fetches cost data from AWS Cost Explorer
- Publishes to CloudWatch Metrics
- Exports to Prometheus (optional)
- Runs every 6 hours

**IAM Permissions**:
```json
{
  "Effect": "Allow",
  "Action": [
    "ce:GetCostAndUsage",
    "ce:GetCostForecast"
  ],
  "Resource": "*"
}
```

### Log Management

**Log Archiving System**:
- Lambda function (`log_exporter.py`) exports CloudWatch logs to S3
- Automated retention policies
- Long-term storage for compliance
- Cost optimization (S3 cheaper than CloudWatch)

**Log Export Configuration**:
```hcl
resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/sdt-${var.environment}-${var.service_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "log_exporter" {
  function_name = "sdt-${var.environment}-log-exporter"
  handler       = "log_exporter.lambda_handler"
  runtime       = "python3.11"
  # ...
}
```

### CloudWatch Alarms

**Configured Alarms**:
- ECS CPU > 80%
- ECS Memory > 80%
- RDS CPU > 80%
- RDS Storage < 10GB
- RDS Connections > 80% of max
- ALB Unhealthy Targets > 0
- ALB 5XX Errors > 10/min
- ALB Response Time > 1s

**Notification**: SNS topic → Email/Slack

## Data Services Deployment

### MongoDB

**Sprint 3 Configuration**:
- Deployed as ECS task
- Stateless mode (no EFS in Sprint 3)
- Legacy naming convention support
- Service discovery via Cloud Map

**Task Definition**:
```json
{
  "family": "sdt-dev-mongodb",
  "containerDefinitions": [{
    "name": "mongodb",
    "image": "<ecr-repo>/mongodb:latest",
    "portMappings": [{ "containerPort": 27017 }],
    "environment": [
      { "name": "MONGO_INITDB_ROOT_USERNAME", "value": "admin" }
    ],
    "secrets": [
      { "name": "MONGO_INITDB_ROOT_PASSWORD", "valueFrom": "<secret-arn>" }
    ]
  }]
}
```

**Sprint 4 Plan**: Add EFS for persistent storage

### RabbitMQ

**Sprint 3 Fixes**:
- Changed user to `999:999` (fixed Erlang cookie permissions)
- Added `/tmp` mount for Erlang runtime
- Stored Erlang cookie in Secrets Manager
- Stateless mode (no EFS)

**Task Definition**:
```json
{
  "family": "sdt-dev-rabbitmq",
  "containerDefinitions": [{
    "name": "rabbitmq",
    "image": "<ecr-repo>/rabbitmq:latest",
    "user": "999:999",
    "portMappings": [
      { "containerPort": 5672 },
      { "containerPort": 15672 }
    ],
    "environment": [
      { "name": "TMPDIR", "value": "/tmp" }
    ],
    "secrets": [
      { "name": "RABBITMQ_ERLANG_COOKIE", "valueFrom": "<secret-arn>" }
    ]
  }]
}
```

### Redis

**Configuration**:
- Deployed as ECS task
- Service discovery via Cloud Map
- Used for session management and caching

### Data Services ALB

**Sprint 3 Addition**: Dedicated ALB for data services

**Purpose**:
- Health checks for MongoDB, RabbitMQ, Redis
- Internal load balancing
- Service discovery integration

## CloudFront CDN Integration

### Sprint 3 Implementation

**New Module**: `infrastructure/modules/cloudfront/`

**Features**:
- CloudFront distribution for frontend
- Managed caching policies
- Cache behavior for static assets and API routes
- OAuth redirect URL fixes

**Configuration**:
```hcl
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = aws_amplify_app.frontend.default_domain
    origin_id   = "amplify"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "amplify"
    viewer_protocol_policy = "redirect-to-https"
    
    cache_policy_id = data.aws_cloudfront_cache_policy.managed.id
  }
}
```

**OAuth Redirect Fix**:
- Updated all OAuth redirect URLs from ALB to CloudFront
- Fixed 404 errors on OAuth callbacks
- Resolved user redirect issue after login

## Secrets Management

### AWS Secrets Manager

**Secrets Stored**:
- Database passwords (RDS, MongoDB)
- JWT secret
- OAuth client secrets (Google)
- API keys (Google API)
- Erlang cookie (RabbitMQ)
- Redis password

**Access Pattern**:
```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name = "sdt/${var.environment}/db-password"
}

# ECS task definition references secret
"secrets": [
  {
    "name": "DB_PASSWORD",
    "valueFrom": "${aws_secretsmanager_secret.db_password.arn}"
  }
]
```

**Sprint 3 Update**: Replaced OpenAI API key with Google API secret

## Deployment Strategies

### Rolling Deployment

**Default Strategy**: ECS rolling update

**Configuration**:
```hcl
deployment_configuration {
  maximum_percent         = 200
  minimum_healthy_percent = 100
}
```

**Process**:
1. Start new tasks with new image
2. Wait for health checks to pass
3. Stop old tasks
4. Repeat until all tasks updated

### Blue-Green Deployment

**Future Enhancement**: Use CodeDeploy for blue-green

**Benefits**:
- Zero downtime
- Instant rollback
- Traffic shifting control

## Monitoring & Alerting

### Slack Notifications

**Events Notified**:
- Deployment started
- Deployment completed (success/failure)
- Health check results
- SonarQube quality gate status
- Infrastructure changes

**Notification Format**:
```json
{
  "text": "Deployment Status",
  "attachments": [{
    "color": "good",
    "fields": [
      { "title": "Environment", "value": "dev", "short": true },
      { "title": "Services", "value": "user-service, task-service", "short": true },
      { "title": "Status", "value": "Success", "short": true },
      { "title": "Duration", "value": "5m 32s", "short": true }
    ]
  }]
}
```

**Sprint 3 Fix**: Removed multi-line fields to prevent malformed notifications

### CloudWatch Dashboards

**ECS Dashboard**:
- Task count per service
- CPU utilization
- Memory utilization
- Network I/O

**RDS Dashboard**:
- CPU utilization
- Database connections
- Read/Write IOPS
- Storage space

## Security

### IAM Roles

**ECS Task Execution Role**:
- Pull images from ECR
- Write logs to CloudWatch
- Read secrets from Secrets Manager

**ECS Task Role**:
- Access S3 buckets
- Read secrets
- Publish to SNS
- Write to CloudWatch Metrics

**Principle of Least Privilege**: Each role has only required permissions

### Network Security

**Security Groups**:
- ALB: Allow 80/443 from internet
- ECS: Allow traffic from ALB only
- RDS: Allow traffic from ECS only
- Data Services: Allow traffic from ECS only

**Private Subnets**:
- All compute and data resources in private subnets
- No direct internet access
- Egress via NAT Gateway

### Secrets Rotation

**Current**: Manual rotation
**Future**: Automated rotation with Lambda

## Cost Optimization

### Sprint 3 Achievements

**Change Detection**:
- 60% reduction in unnecessary builds
- Deploy only changed services
- Lower ECR storage costs

**Image Lifecycle Policies**:
- Keep last 10 tagged images
- Delete untagged images after 7 days

**Log Retention**:
- Dev: 7 days
- Staging: 30 days
- Production: 90 days

**Cost Monitoring**:
- Real-time cost tracking
- Budget alerts
- Cost breakdown by service

### Cost Estimates

**Development Environment** (per month):
- ECS Fargate: $150-200
- RDS (db.t3.micro): $15-20
- NAT Gateway: $30-45
- ALB: $20-25
- S3: $5-10
- CloudWatch: $10-15
- **Total**: ~$230-315/month

**Production Environment** (per month):
- ECS Fargate: $500-800
- RDS (db.r5.large, Multi-AZ): $300-400
- NAT Gateway (2): $60-90
- ALB: $40-50
- S3: $20-30
- CloudWatch: $30-50
- **Total**: ~$950-1,420/month

## Troubleshooting

### Pipeline Failures

**Issue**: Maven build fails with "Could not find artifact"

**Solution**:
1. Check module paths: `skilltracker-common/common-security`
2. Build shared dependencies first
3. Clear Maven cache: `mvn clean install -U`

**Issue**: SonarQube analysis fails

**Solution**:
1. Verify SonarQube server is running
2. Check `SONAR_TOKEN` secret
3. Verify network connectivity
4. Check SonarQube server logs

**Issue**: ECS deployment fails with `CannotPullContainerError`

**Solution**:
1. Verify image exists in ECR
2. Check ECS task execution role has ECR permissions
3. Use `:latest` tag instead of commit SHA
4. Verify ECR repository policy

### Infrastructure Issues

**Issue**: RabbitMQ container fails to start

**Solution** (Sprint 3 Fix):
1. Change user to `999:999`
2. Add `/tmp` mount point
3. Store Erlang cookie in Secrets Manager
4. Check CloudWatch logs for permission errors

**Issue**: MongoDB connection failures

**Solution**:
1. Verify service discovery DNS: `mongodb.local`
2. Check security group allows traffic
3. Verify MongoDB credentials in Secrets Manager
4. Check CloudWatch logs

**Issue**: Health checks failing

**Solution**:
1. Verify service is running: `aws ecs list-tasks`
2. Check ALB target group health
3. Verify health endpoint: `/actuator/health`
4. Check security group rules

## Best Practices

### CI/CD

1. **Fail Fast**: Run quick tests first (unit tests before integration tests)
2. **Parallel Execution**: Build services in parallel when possible
3. **Caching**: Cache Maven dependencies and Docker layers
4. **Idempotency**: Ensure pipelines can be re-run safely
5. **Rollback Plan**: Always have a rollback strategy

### Infrastructure

1. **Version Control**: All infrastructure in Git
2. **Immutable Infrastructure**: Replace, don't modify
3. **Environment Parity**: Keep dev/staging/prod similar
4. **Automated Testing**: Test infrastructure changes in dev first
5. **Documentation**: Keep docs up-to-date

### Monitoring

1. **Proactive Alerts**: Alert before issues become critical
2. **Actionable Alerts**: Every alert should have a runbook
3. **Log Everything**: Comprehensive logging for debugging
4. **Metrics**: Track business and technical metrics
5. **Dashboards**: Create dashboards for different audiences

## Future Enhancements

### Sprint 4 Plans

1. **EFS for Data Services**: Add persistent storage for MongoDB and RabbitMQ
2. **Automated Secrets Rotation**: Implement Lambda-based rotation
3. **Multi-Region Deployment**: DR setup in another region
4. **Advanced Monitoring**: Application Performance Monitoring (APM)
5. **Chaos Engineering**: Test resilience with chaos experiments

### Long-Term Roadmap

1. **Service Mesh**: AWS App Mesh for advanced routing
2. **GitOps**: ArgoCD or Flux for Kubernetes-style deployments
3. **Policy as Code**: OPA for policy enforcement
4. **FinOps**: Advanced cost optimization and chargeback
5. **Security Scanning**: Container vulnerability scanning in pipeline

## Sprint Metrics

### Sprint 3 Performance

- **Total Deployments**: 53 commits deployed
- **Failed Deployments**: 8 (all resolved)
- **Success Rate**: 85%
- **Average Build Time**: ~15 minutes (12 services)
- **Change Detection Efficiency**: 60% reduction in unnecessary builds
- **Microservices Deployed**: 12/12 (100%)

### Key Learnings

1. **Build Order Matters**: Shared dependencies must be built first
2. **Container Permissions**: Verify file system permissions for non-root users
3. **Image Tagging**: Use stable tags for deployments, commit tags for traceability
4. **Change Detection ROI**: Intelligent detection significantly reduces costs
5. **Observability First**: Comprehensive monitoring prevents debugging delays

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
