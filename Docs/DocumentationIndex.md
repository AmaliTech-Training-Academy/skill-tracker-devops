# Skill Tracker - Documentation Index

## Overview

Complete documentation for the Skill Tracker platform - a microservices-based application deployed on AWS with comprehensive DevOps practices.

## Quick Links

| Document | Purpose | Audience |
|----------|---------|----------|
| [README.md](../README.md) | Getting started, quick reference | All |
| [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) | System architecture and design decisions | Architects, Senior Devs |
| [DiagramsDocs.md](DiagramsDocs.md) | Visual architecture diagrams | All |
| [FrontendDocs.md](FrontendDocs.md) | Angular frontend documentation | Frontend Developers |
| [BackendDocs.md](BackendDocs.md) | Microservices backend documentation | Backend Developers |
| [DevOpsDocs.md](DevOpsDocs.md) | CI/CD, infrastructure, monitoring | DevOps Engineers |
| [PROJECT_SUMMARY.md](../infrastructure/PROJECT_SUMMARY.md) | Project overview and structure | Project Managers |
| [QUICK_START.md](../infrastructure/QUICK_START.md) | Fast setup guide | New Team Members |

## Documentation Structure

### 1. Getting Started

**For New Team Members**:
1. Start with [README.md](../README.md) - Overview and prerequisites
2. Review [DiagramsDocs.md](DiagramsDocs.md) - Visual architecture overview
3. Read [QUICK_START.md](../infrastructure/QUICK_START.md) - 5-minute setup
4. Review [PROJECT_SUMMARY.md](../infrastructure/PROJECT_SUMMARY.md) - Project structure

**For Developers**:
1. Frontend: [FrontendDocs.md](FrontendDocs.md)
2. Backend: [BackendDocs.md](BackendDocs.md)
3. Architecture: [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md)

**For DevOps**:
1. [DevOpsDocs.md](DevOpsDocs.md) - CI/CD and infrastructure
2. [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - System design
3. [README.md](../infrastructure/README.md) - Deployment commands

### 2. By Role

#### Frontend Developers

**Primary Documents**:
- [FrontendDocs.md](FrontendDocs.md) - Angular app, Amplify, CloudFront
- [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - System architecture
- [DevOpsDocs.md](DevOpsDocs.md) - Deployment process

**Key Topics**:
- Angular application structure
- AWS Amplify hosting
- CloudFront CDN configuration
- OAuth authentication flow
- API integration
- Build and deployment process

#### Backend Developers

**Primary Documents**:
- [BackendDocs.md](BackendDocs.md) - Microservices architecture
- [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - Design decisions
- [DevOpsDocs.md](DevOpsDocs.md) - CI/CD pipelines

**Key Topics**:
- 12 microservices overview
- Spring Boot configuration
- Service discovery (Eureka)
- Database architecture (PostgreSQL + MongoDB)
- RabbitMQ messaging
- JWT authentication
- API documentation

#### DevOps Engineers

**Primary Documents**:
- [DevOpsDocs.md](DevOpsDocs.md) - Complete DevOps guide
- [README.md](../infrastructure/README.md) - Infrastructure commands
- [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - Infrastructure design

**Key Topics**:
- CI/CD pipelines (GitHub Actions)
- Terraform infrastructure
- AWS ECS deployment
- Monitoring (Grafana, CloudWatch)
- Cost optimization
- Security best practices

#### Architects

**Primary Documents**:
- [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - Detailed architecture
- [PROJECT_SUMMARY.md](../infrastructure/PROJECT_SUMMARY.md) - High-level overview
- [BackendDocs.md](BackendDocs.md) - Service architecture

**Key Topics**:
- Microservices patterns
- Design decisions and rationale
- Scalability considerations
- Security architecture
- Data flow diagrams

### 3. By Task

#### Setting Up Development Environment

1. [README.md](../README.md) - Prerequisites and setup
2. [QUICK_START.md](../infrastructure/QUICK_START.md) - Quick setup commands
3. [FRONTEND.md](FrontendDocs.md) or [BACKEND.md](BackendDocs.md) - Specific setup

#### Deploying Infrastructure

1. [README.md](../README.md) - Terraform commands
2. [DEVOPS.md](DevOpsDocs.md) - Deployment strategies
3. [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - Infrastructure components

#### Adding a New Microservice

1. [BACKEND.md](BackendDocs.md) - Service structure and patterns
2. [DEVOPS.md](DevOpsDocs.md) - CI/CD integration
3. [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - Design considerations

#### Troubleshooting Issues

1. [DEVOPS.md](DevOpsDocs.md) - Common issues and solutions
2. [BACKEND.md](BackendDocs.md) - Service-specific troubleshooting
3. [FRONTEND.md](FrontendDocs.md) - Frontend issues

#### Monitoring and Observability

1. [DEVOPS.md](DevOpsDocs.md) - Monitoring setup
2. [ARCHITECTURE.md](../infrastructure/ARCHITECTURE.md) - Observability design
3. [README.md](../README.md) - Accessing dashboards

## Technology Stack

### Frontend
- **Framework**: Angular
- **Hosting**: AWS Amplify
- **CDN**: CloudFront
- **Authentication**: OAuth 2.0 (Google)

### Backend
- **Framework**: Spring Boot 3.x
- **Language**: Java 17
- **Build Tool**: Maven
- **Service Discovery**: Eureka
- **Configuration**: Spring Cloud Config
- **API Gateway**: Spring Cloud Gateway

### Databases
- **Relational**: PostgreSQL 15 (RDS)
- **Document**: MongoDB 6 (ECS)
- **Cache**: Redis (ECS)
- **Message Queue**: RabbitMQ (ECS)

### Infrastructure
- **Cloud Provider**: AWS
- **IaC**: Terraform
- **Compute**: ECS Fargate
- **Networking**: VPC, ALB, CloudFront
- **Storage**: S3, EFS
- **Monitoring**: CloudWatch, Grafana

### DevOps
- **CI/CD**: GitHub Actions
- **Code Quality**: SonarQube
- **Container Registry**: ECR
- **Secrets**: AWS Secrets Manager
- **Notifications**: Slack

## Microservices

**Active Services**: 15 (12 business + 3 core)  
**Infrastructure Ready**: 4 additional services pending development

| Service | Port | Database | Status | Documentation |
|---------|------|----------|---------------|
| Config Server | 8081 | - | [BACKEND.md](BackendDocs.md#centralized-configuration) |
| Discovery Server | 8082 | - | [BACKEND.md](BackendDocs.md#service-discovery) |
| API Gateway | 8080 | - | [BACKEND.md](BackendDocs.md#api-gateway-pattern) |
| User Service | 8083 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Task Service | 8084 | PostgreSQL + MongoDB | [BACKEND.md](BackendDocs.md#polyglot-persistence-rationale) |
| Skill Service | 8085 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Assessment Service | 8086 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Analytics Service | 8087 | MongoDB | [BACKEND.md](BackendDocs.md#mongodb-services) |
| Feedback Service | 8088 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Notification Service | 8089 | MongoDB + RabbitMQ | [BACKEND.md](BackendDocs.md#asynchronous-communication-rabbitmq) |
| Report Service | 8090 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Recommendation Service | 8091 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Search Service | 8092 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Integration Service | 8093 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |
| Collaboration Service | 8094 | PostgreSQL | [BACKEND.md](BackendDocs.md#microservices-architecture) |

## AWS Resources

### Compute
- **ECS Cluster**: Fargate launch type
- **Services**: 12 microservices + 3 data services
- **Auto-scaling**: CPU and memory-based

### Networking
- **VPC**: Multi-AZ deployment
- **Subnets**: Public (ALB, NAT) + Private (ECS, RDS)
- **Load Balancers**: ALB for backend, CloudFront for frontend
- **Security Groups**: Restrictive ingress/egress

### Data
- **RDS**: PostgreSQL 15 (Multi-AZ in production)
- **ECS Tasks**: MongoDB, RabbitMQ, Redis
- **S3**: User uploads, static assets, logs
- **EFS**: Persistent storage (planned for Sprint 4)

### Monitoring
- **CloudWatch**: Logs, metrics, alarms
- **Grafana**: Custom dashboards
- **X-Ray**: Distributed tracing (staging/prod)

## Common Tasks

### Deploy to Development

```bash
# Using Terraform
cd infrastructure/envs/dev
terraform plan
terraform apply

# Using Makefile
make plan ENV=dev
make apply ENV=dev
```

**Documentation**: [README.md](README.md#usage), [DEVOPS.md](DEVOPS.md#terraform-workflow)

### Update a Microservice

```bash
# Build and push Docker image
docker build -t user-service:latest .
docker tag user-service:latest <ecr-repo>:latest
docker push <ecr-repo>:latest

# Update ECS service
aws ecs update-service --cluster sdt-dev-cluster --service user-service --force-new-deployment
```

**Documentation**: [BACKEND.md](BackendDocs.md#service-communication), [DEVOPS.md](DEVOPS.md#deployment-strategies)

### View Logs

```bash
# CloudWatch Logs
aws logs tail /ecs/sdt-dev-user-service --follow

# Grafana Dashboard
# Access: http://<grafana-url>:3000
```

**Documentation**: [DEVOPS.md](DEVOPS.md#log-management)

### Check Service Health

```bash
# Via ALB
curl http://<alb-dns>/api/users/actuator/health

# Via ECS
aws ecs describe-services --cluster sdt-dev-cluster --services user-service
```

**Documentation**: [BACKEND.md](BackendDocs.md#health-checks), [DEVOPS.md](DEVOPS.md#enhanced-health-checks)

## Sprint 3 Highlights

### Achievements

1. **Multi-Service Pipeline**: Expanded from 3 to 12 microservices
2. **SonarQube Integration**: Automated code quality analysis
3. **Intelligent Change Detection**: 60% reduction in unnecessary builds
4. **CloudFront CDN**: Enhanced frontend delivery
5. **Grafana Monitoring**: Complete observability stack
6. **Cost Monitoring**: Real-time cost tracking and optimization

### Key Fixes

1. **Maven Build Dependencies**: Resolved module path issues
2. **RabbitMQ Permissions**: Fixed Erlang cookie errors
3. **ECS Image Tagging**: Resolved CannotPullContainerError
4. **OAuth Redirects**: Fixed CloudFront callback URLs
5. **Health Check Notifications**: Improved Slack integration

**Full Details**: [DEVOPS.md](DEVOPS.md#sprint-3-achievements)

## Troubleshooting Guide

### Quick Reference

| Issue | Document | Section |
|-------|----------|---------|
| Pipeline failures | [DEVOPS.md](DevOpsDocs.md) | Troubleshooting > Pipeline Failures |
| Service not starting | [BACKEND.md](BackendDocs.md) | Troubleshooting |
| Frontend 404 errors | [FRONTEND.md](FrontendDocs.md) | Troubleshooting |
| Database connection | [BACKEND.md](BackendDocs.md) | Troubleshooting > Database Connection Failures |
| RabbitMQ issues | [DEVOPS.md](DevOpsDocs.md) | Data Services Deployment > RabbitMQ |
| OAuth callback errors | [FRONTEND.md](FrontendDocs.md) | Troubleshooting > OAuth Callback 404 |
| Infrastructure errors | [DEVOPS.md](DevOpsDocs.md) | Troubleshooting > Infrastructure Issues |

## Best Practices

### Development

1. **Branch Strategy**: Feature branches → dev → staging → production
2. **Code Review**: All changes require PR review
3. **Testing**: Unit tests + integration tests before merge
4. **Documentation**: Update docs with code changes

**Reference**: [BACKEND.md](BackendDocs.md#best-practices), [FRONTEND.md](FRONTEND.md#best-practices)

### Deployment

1. **Test in Dev First**: Always test changes in dev environment
2. **Plan Before Apply**: Review Terraform plan carefully
3. **Gradual Rollout**: Dev → Staging → Production
4. **Rollback Plan**: Always have a rollback strategy

**Reference**: [DEVOPS.md](DEVOPS.md#best-practices)

### Security

1. **No Hardcoded Secrets**: Use AWS Secrets Manager
2. **Least Privilege**: Minimal IAM permissions
3. **Private Subnets**: No direct internet access for compute
4. **Encryption**: At rest and in transit
5. **Regular Updates**: Keep dependencies up-to-date

**Reference**: [ARCHITECTURE.md](ARCHITECTURE.md#security), [BACKEND.md](BackendDocs.md#security-best-practices)

## Monitoring & Alerts

### Dashboards

- **Grafana**: http://<grafana-url>:3000
  - Service Overview
  - Infrastructure Monitoring
  - Cost Monitoring
  - Live Cost Tracking

- **CloudWatch**: AWS Console → CloudWatch → Dashboards
  - ECS Dashboard
  - RDS Dashboard

**Reference**: [DEVOPS.md](DEVOPS.md#grafana-dashboards)

### Alerts

- **Slack**: #devops-alerts channel
- **Email**: Via SNS subscriptions
- **PagerDuty**: (Optional) For critical alerts

**Reference**: [DEVOPS.md](DEVOPS.md#slack-notifications)

## Cost Optimization

### Current Measures

1. **Intelligent Change Detection**: Deploy only changed services
2. **Image Lifecycle Policies**: Delete old images
3. **Log Retention**: Environment-specific retention
4. **Auto-scaling**: Scale down during low traffic
5. **Spot Instances**: (Planned) For non-critical workloads

### Cost Estimates

- **Development**: ~$230-315/month
- **Staging**: ~$500-700/month
- **Production**: ~$950-1,420/month

**Reference**: [DEVOPS.md](DEVOPS.md#cost-optimization)

## Future Roadmap

### Sprint 4 Plans

1. **EFS for Data Services**: Persistent storage for MongoDB and RabbitMQ
2. **Automated Secrets Rotation**: Lambda-based rotation
3. **Multi-Region Deployment**: DR setup
4. **Advanced Monitoring**: APM integration
5. **Chaos Engineering**: Resilience testing

### Long-Term

1. **Service Mesh**: AWS App Mesh
2. **GitOps**: ArgoCD or Flux
3. **Policy as Code**: OPA integration
4. **FinOps**: Advanced cost optimization
5. **Security Scanning**: Container vulnerability scanning

**Reference**: [DEVOPS.md](DEVOPS.md#future-enhancements), [BACKEND.md](BackendDocs.md#future-enhancements)

## Support & Contact

### Documentation Issues

- **Report**: Create issue in repository
- **Update**: Submit PR with documentation changes
- **Questions**: Ask in #devops-support Slack channel

### Getting Help

1. **Check Documentation**: Search this index first
2. **Search Logs**: CloudWatch or Grafana
3. **Ask Team**: Slack channels
4. **Escalate**: On-call engineer (production issues)

## Contributing

### Documentation Updates

1. Keep docs in sync with code changes
2. Use clear, concise language
3. Include examples and code snippets
4. Update this index when adding new docs

### Code Contributions

1. Follow coding standards
2. Write tests
3. Update documentation
4. Pass SonarQube quality gates

**Reference**: [BACKEND.md](BackendDocs.md#testing), [DEVOPS.md](DEVOPS.md#sonarqube-integration)

## Version History

| Version | Date | Changes | Sprint |
|---------|------|---------|--------|
| 1.0.0 | 2025-11-21 | Initial documentation | Sprint 3 |
| 1.1.0 | TBD | EFS integration | Sprint 4 |

## References

### External Documentation

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Angular Documentation](https://angular.io/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Internal Resources

- **Git Repository**: AmaliTech-Training-Academy/skill-tracker-devops
- **Slack Channels**: #devops-team, #devops-alerts, #devops-support
- **Grafana**: http://<grafana-url>:3000
- **SonarQube**: http://<sonarqube-url>:9000

---

**Last Updated**: November 28, 2025
**Maintained By**: DevOps Team
**Status**: Active Development
