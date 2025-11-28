# Quick Reference - Skill Tracker

Essential commands and information for daily operations.

## Quick Access

| Resource | URL/Command |
|----------|-------------|
| **Grafana** | `http://<grafana-url>:3000` |
| **SonarQube** | `http://<sonarqube-url>:9000` |
| **AWS Console** | `https://console.aws.amazon.com` |
| **GitHub Actions** | `https://github.com/<org>/<repo>/actions` |
| **Slack Alerts** | `#devops-alerts` |

## Common Commands

### Terraform

```bash
# Initialize
cd infrastructure/envs/dev
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Show outputs
terraform output

# Destroy (careful!)
terraform destroy
```

### AWS CLI

```bash
# List ECS services
aws ecs list-services --cluster sdt-dev-cluster

# Describe service
aws ecs describe-services --cluster sdt-dev-cluster --services user-service

# View logs
aws logs tail /ecs/sdt-dev-user-service --follow

# Update service (force new deployment)
aws ecs update-service --cluster sdt-dev-cluster --service user-service --force-new-deployment

# List ECR images
aws ecr list-images --repository-name sdt/dev/user-service

# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Docker

```bash
# Build image
docker build -t user-service:latest .

# Tag for ECR
docker tag user-service:latest <ecr-repo>:latest

# Push to ECR
docker push <ecr-repo>:latest

# Run locally
docker run -p 8083:8083 user-service:latest
```

### Maven

```bash
# Build shared dependencies
mvn clean install -pl skilltracker-common/common-event
mvn clean install -pl skilltracker-common/common-security
mvn clean install -pl skilltracker-common/common-util

# Build service
mvn clean install -pl user-service

# Run tests
mvn test -pl user-service

# Skip tests
mvn clean install -DskipTests

# SonarQube analysis
mvn sonar:sonar -Dsonar.projectKey=user-service -Dsonar.host.url=<sonar-url> -Dsonar.login=<token>
```

### Git

```bash
# Create feature branch
git checkout -b feature/new-feature

# Commit changes
git add .
git commit -m "Add new feature"

# Push to remote
git push origin feature/new-feature

# Merge to dev
git checkout dev
git merge feature/new-feature
git push origin dev
```

## Troubleshooting

### Service Not Starting

```bash
# Check service status
aws ecs describe-services --cluster sdt-dev-cluster --services user-service

# Check task status
aws ecs list-tasks --cluster sdt-dev-cluster --service-name user-service

# Describe task
aws ecs describe-tasks --cluster sdt-dev-cluster --tasks <task-arn>

# View logs
aws logs tail /ecs/sdt-dev-user-service --follow
```

### Database Connection Issues

```bash
# Test RDS connectivity
aws rds describe-db-instances --db-instance-identifier sdt-dev-db

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Test connection from ECS task
aws ecs execute-command --cluster sdt-dev-cluster --task <task-id> --container user-service --interactive --command "/bin/sh"
```

### Pipeline Failures

```bash
# View workflow runs
gh run list --repo <org>/<repo>

# View specific run
gh run view <run-id>

# Re-run failed jobs
gh run rerun <run-id>

# View logs
gh run view <run-id> --log
```

## Monitoring

### CloudWatch Queries

```bash
# Query logs
aws logs filter-log-events --log-group-name /ecs/sdt-dev-user-service --filter-pattern "ERROR"

# Get metrics
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=user-service --start-time 2025-11-28T00:00:00Z --end-time 2025-11-28T23:59:59Z --period 3600 --statistics Average
```

### Grafana Dashboards

- **Service Overview**: CPU, Memory, Request Rate, Error Rate
- **Infrastructure**: VPC, ALB, RDS, ECS metrics
- **Cost Monitoring**: Daily costs, monthly trends
- **Live Cost**: Real-time cost tracking

## Secrets Management

### AWS Secrets Manager

```bash
# List secrets
aws secretsmanager list-secrets

# Get secret value
aws secretsmanager get-secret-value --secret-id sdt/dev/db-password

# Update secret
aws secretsmanager update-secret --secret-id sdt/dev/db-password --secret-string "new-password"

# Create secret
aws secretsmanager create-secret --name sdt/dev/new-secret --secret-string "secret-value"
```

## Emergency Procedures

### Rollback Deployment

```bash
# List task definitions
aws ecs list-task-definitions --family-prefix sdt-dev-user-service

# Update service to previous version
aws ecs update-service --cluster sdt-dev-cluster --service user-service --task-definition sdt-dev-user-service:123
```

### Scale Service

```bash
# Scale up
aws ecs update-service --cluster sdt-dev-cluster --service user-service --desired-count 4

# Scale down
aws ecs update-service --cluster sdt-dev-cluster --service user-service --desired-count 1
```

### Stop All Tasks

```bash
# List tasks
aws ecs list-tasks --cluster sdt-dev-cluster --service-name user-service

# Stop task
aws ecs stop-task --cluster sdt-dev-cluster --task <task-arn>
```

## Performance

### Check Service Health

```bash
# Via ALB
curl http://<alb-dns>/api/users/actuator/health

# Via direct ECS task IP (if accessible)
curl http://<task-ip>:8083/actuator/health
```

### Check Metrics

```bash
# ECS metrics
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=user-service --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average

# RDS metrics
aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization --dimensions Name=DBInstanceIdentifier,Value=sdt-dev-db --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average
```

## Cost Management

### View Current Costs

```bash
# Get cost for last 7 days
aws ce get-cost-and-usage --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) --granularity DAILY --metrics BlendedCost --group-by Type=TAG,Key=Environment

# Get cost forecast
aws ce get-cost-forecast --time-period Start=$(date -u +%Y-%m-%d),End=$(date -u -d '30 days' +%Y-%m-%d) --metric BLENDED_COST --granularity MONTHLY
```

## CI/CD

### Trigger Manual Deployment

```bash
# Via GitHub CLI
gh workflow run manual-service-deploy.yml -f environment=dev -f service=user-service -f image_tag=latest

# Via API
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token <github-token>" \
  https://api.github.com/repos/<org>/<repo>/actions/workflows/manual-service-deploy.yml/dispatches \
  -d '{"ref":"main","inputs":{"environment":"dev","service":"user-service","image_tag":"latest"}}'
```

### Check Pipeline Status

```bash
# List recent runs
gh run list --limit 10

# Watch run
gh run watch <run-id>
```

## Logs

### Tail Logs

```bash
# Single service
aws logs tail /ecs/sdt-dev-user-service --follow

# Multiple services (use tmux or separate terminals)
aws logs tail /ecs/sdt-dev-user-service --follow &
aws logs tail /ecs/sdt-dev-task-service --follow &
```

### Search Logs

```bash
# Search for errors
aws logs filter-log-events --log-group-name /ecs/sdt-dev-user-service --filter-pattern "ERROR" --start-time $(date -u -d '1 hour ago' +%s)000

# Search for specific user
aws logs filter-log-events --log-group-name /ecs/sdt-dev-user-service --filter-pattern "user_id=123"
```

## Networking

### Test Connectivity

```bash
# Test ALB
curl -I http://<alb-dns>

# Test service via ALB
curl http://<alb-dns>/api/users/actuator/health

# Test CloudFront
curl -I https://<cloudfront-domain>
```

### Check Security Groups

```bash
# List security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=skill-tracker"

# Check specific security group
aws ec2 describe-security-groups --group-ids <sg-id>
```

## Service Ports

| Service | Port | Health Check |
|---------|------|--------------|
| Config Server | 8081 | `/actuator/health` |
| Discovery Server | 8082 | `/actuator/health` |
| API Gateway | 8080 | `/actuator/health` |
| User Service | 8083 | `/actuator/health` |
| Task Service | 8084 | `/actuator/health` |
| Skill Service | 8085 | `/actuator/health` |
| Assessment Service | 8086 | `/actuator/health` |
| Analytics Service | 8087 | `/actuator/health` |
| Feedback Service | 8088 | `/actuator/health` |
| Notification Service | 8089 | `/actuator/health` |
| Report Service | 8090 | `/actuator/health` |
| Recommendation Service | 8091 | `/actuator/health` |
| Search Service | 8092 | `/actuator/health` |
| Integration Service | 8093 | `/actuator/health` |
| Collaboration Service | 8094 | `/actuator/health` |
| MongoDB | 27017 | - |
| RabbitMQ | 5672 | - |
| RabbitMQ Management | 15672 | - |
| Redis | 6379 | - |

## Environment Variables

### Required for All Services

```bash
SPRING_PROFILES_ACTIVE=dev
CONFIG_SERVER_URL=http://config-server.local:8081
EUREKA_SERVER_URL=http://discovery-server.local:8082/eureka
```

### Database Services

```bash
# PostgreSQL
RDS_ENDPOINT=sdt-dev-db.xxxxx.us-east-1.rds.amazonaws.com
DB_NAME=skilltracker
DB_USERNAME=admin
DB_PASSWORD=<from-secrets-manager>

# MongoDB
MONGODB_HOST=mongodb.local
MONGODB_PORT=27017
MONGODB_DATABASE=skilltracker

# Redis
REDIS_HOST=redis.local
REDIS_PORT=6379

# RabbitMQ
RABBITMQ_HOST=rabbitmq.local
RABBITMQ_PORT=5672
```

### Authentication

```bash
JWT_SECRET=<from-secrets-manager>
GOOGLE_CLIENT_ID=<from-secrets-manager>
GOOGLE_CLIENT_SECRET=<from-secrets-manager>
LOGIN_URL=https://<cloudfront-domain>
COOKIE_SECURE=true
```

## Support Contacts

| Issue Type | Contact | Channel |
|------------|---------|---------|
| Infrastructure | DevOps Team | #devops-support |
| Backend Services | Backend Team | #backend-support |
| Frontend | Frontend Team | #frontend-support |
| Security | Security Team | #security-alerts |
| Production Incidents | On-Call Engineer | PagerDuty |

## Documentation Links

- [Full Documentation Index](DOCUMENTATION_INDEX.md)
- [Architecture Guide](ARCHITECTURE.md)
- [Frontend Guide](FRONTEND.md)
- [Backend Guide](BACKEND.md)
- [DevOps Guide](DEVOPS.md)
- [Diagrams](DIAGRAMS.md)
- [Changelog](CHANGELOG.md)

## Quick Wins

### Reduce Costs

1. Stop non-essential services in dev after hours
2. Use Spot instances for non-critical workloads
3. Review and delete old ECR images
4. Optimize log retention periods
5. Right-size ECS tasks based on actual usage

### Improve Performance

1. Enable CloudFront caching for static assets
2. Add Redis caching for frequently accessed data
3. Optimize database queries
4. Enable connection pooling
5. Use async processing for long-running tasks

### Enhance Security

1. Rotate secrets regularly
2. Review IAM permissions
3. Enable MFA for AWS accounts
4. Update security groups to least privilege
5. Enable AWS GuardDuty

---

**Last Updated**: November 28, 2025
**Maintained By**: DevOps Team
