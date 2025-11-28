# Changelog - Skill Tracker Documentation

All notable changes to the Skill Tracker project documentation and infrastructure will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-28

### Added - Documentation

- **FRONTEND.md**: Complete frontend documentation
  - Angular application architecture
  - AWS Amplify hosting configuration
  - CloudFront CDN integration
  - OAuth authentication flow
  - API integration patterns
  - Build and deployment process
  - Troubleshooting guide

- **BACKEND.md**: Comprehensive backend documentation
  - 12 microservices architecture overview
  - Spring Boot configuration
  - Service discovery with Eureka
  - Centralized configuration with Spring Cloud Config
  - Database architecture (PostgreSQL + MongoDB)
  - RabbitMQ messaging patterns
  - JWT authentication and OAuth 2.0
  - Health checks and monitoring
  - Troubleshooting guide

- **DEVOPS.md**: Complete DevOps documentation
  - CI/CD pipeline architecture
  - GitHub Actions workflows
  - SonarQube integration
  - Intelligent change detection
  - Terraform infrastructure as code
  - Grafana monitoring dashboards
  - Cost monitoring and optimization
  - Data services deployment (MongoDB, RabbitMQ, Redis)
  - CloudFront CDN integration
  - Secrets management
  - Deployment strategies
  - Sprint 3 achievements and learnings

- **DIAGRAMS.md**: Visual architecture diagrams
  - System overview diagram
  - Request flow diagrams (frontend and backend)
  - Service discovery flow
  - Authentication flow
  - CI/CD pipeline flow
  - Data flow examples
  - Monitoring and observability flow
  - Cost monitoring flow
  - Network architecture
  - Deployment architecture
  - Service dependencies
  - Auto-scaling behavior

- **DOCUMENTATION_INDEX.md**: Central documentation hub
  - Quick links to all documentation
  - Documentation structure by role
  - Documentation by task
  - Technology stack overview
  - Microservices inventory
  - AWS resources summary
  - Common tasks reference
  - Sprint 3 highlights
  - Troubleshooting quick reference
  - Best practices
  - Cost optimization
  - Future roadmap

- **CHANGELOG.md**: This file
  - Track all documentation and infrastructure changes
  - Version history
  - Sprint-based updates

### Updated

- **README.md**: Enhanced main README
  - Added documentation links
  - Quick start section
  - Architecture overview
  - Sprint 3 achievements
  - Related repositories

### Sprint 3 Infrastructure Changes

#### CI/CD Enhancements

- Expanded pipeline from 3 to 12 microservices
- Integrated SonarQube for automated code quality analysis
- Implemented intelligent change detection (60% cost reduction)
- Fixed Maven build dependency resolution
- Updated image tagging strategy (`:latest` + commit SHA)
- Enhanced health checks for deployed services
- Improved Slack notifications

#### Observability & Monitoring

- Deployed complete Grafana stack with AWS CloudWatch integration
- Created 4 custom dashboards:
  - Service Overview Dashboard
  - Infrastructure Monitoring Dashboard
  - Cost Monitoring Dashboard
  - Live Cost Monitoring Dashboard
- Implemented Lambda cost exporter for real-time cost tracking
- Set up log archiving system (CloudWatch → S3)
- Configured log retention policies

#### Infrastructure Updates

- Added CloudFront CDN module for frontend
- Deployed data services (MongoDB, RabbitMQ, Redis) on ECS
- Created dedicated ALB for data services
- Updated RDS module to expose host endpoint
- Enhanced ECS cluster configuration
- Updated security groups for data services access

#### Service Configuration

- Configured all 12 microservices with proper environment variables
- Integrated PostgreSQL, MongoDB, and RabbitMQ connections
- Set up JWT secret management via Secrets Manager
- Updated OAuth configuration with CloudFront URLs
- Replaced OpenAI API key with Google API secret
- Set `COOKIE_SECURE=true` for production

#### Fixes & Resolutions

- **Maven Build**: Fixed module paths (`skilltracker-common/common-security`)
- **RabbitMQ**: Changed user to `999:999`, fixed Erlang cookie permissions
- **ECS Deployment**: Resolved `CannotPullContainerError` with `:latest` tags
- **CloudFront**: Fixed OAuth redirect URLs and caching policies
- **Health Checks**: Removed curl-based checks, using ALB health checks
- **Notifications**: Fixed multi-line fields in Slack messages

### Metrics

- **Total Deployments**: 53 commits deployed
- **Success Rate**: 85%
- **Average Build Time**: ~15 minutes (12 services)
- **Change Detection Efficiency**: 60% reduction in unnecessary builds
- **Microservices Coverage**: 12/12 (100%)
- **Environments**: Dev (complete), Staging (configured), Production (configured)

## [0.9.0] - 2025-11-10 (Sprint 2)

### Added

- Initial Terraform infrastructure modules
- Basic CI/CD pipeline for 3 services
- RDS PostgreSQL deployment
- ECS Fargate cluster setup
- Basic monitoring with CloudWatch

### Infrastructure

- VPC with public and private subnets
- Application Load Balancer
- ECS cluster with 3 services (auth, content, submission)
- RDS PostgreSQL database
- S3 buckets for storage
- AWS Amplify for frontend hosting

## [0.8.0] - 2025-10-28 (Sprint 1)

### Added

- Project initialization
- Basic documentation (README, ARCHITECTURE)
- Terraform module structure
- Development environment setup

## Upcoming Changes

### [1.1.0] - Sprint 4 (Planned)

#### Infrastructure

- [ ] Add EFS volumes for MongoDB and RabbitMQ persistence
- [ ] Implement automated secrets rotation
- [ ] Set up AWS WAF for CloudFront and ALB
- [ ] Configure AWS Budgets with actionable thresholds
- [ ] Implement distributed tracing with X-Ray in all environments

#### CI/CD

- [ ] Add container vulnerability scanning in pipeline
- [ ] Implement blue-green deployment strategy
- [ ] Add automated rollback on health check failure
- [ ] Enhance SonarQube quality gates
- [ ] Add performance testing in pipeline

#### Monitoring

- [ ] Implement application-level metrics (APM)
- [ ] Add custom CloudWatch metrics for business KPIs
- [ ] Set up distributed tracing dashboards
- [ ] Create runbooks for common alerts
- [ ] Implement log aggregation and analysis

#### Documentation

- [ ] Add API documentation (OpenAPI/Swagger)
- [ ] Create runbooks for operational tasks
- [ ] Add disaster recovery procedures
- [ ] Document incident response process
- [ ] Create onboarding guide for new team members

### [2.0.0] - Future (Long-term)

#### Multi-Region

- [ ] Deploy infrastructure in secondary region
- [ ] Set up cross-region replication
- [ ] Implement global load balancing
- [ ] Configure disaster recovery automation

#### Advanced Features

- [ ] Service mesh (AWS App Mesh)
- [ ] GitOps with ArgoCD or Flux
- [ ] Policy as Code with OPA
- [ ] Advanced cost optimization (FinOps)
- [ ] Chaos engineering implementation

#### Security

- [ ] Implement AWS Security Hub
- [ ] Add runtime security monitoring
- [ ] Set up compliance scanning
- [ ] Implement zero-trust networking
- [ ] Add security incident response automation

## Key Learnings

### Sprint 3

1. **Build Order Matters**: Shared dependencies must be built first. Dependency graphs should be explicitly defined in CI/CD pipelines.

2. **Container User Permissions**: Always verify file system permissions when running containers as non-root users. Use AWS Secrets Manager for sensitive runtime configuration.

3. **Image Tagging Strategy**: Use stable tags (`:latest`) for deployments while maintaining commit-specific tags for traceability and rollbacks.

4. **Change Detection ROI**: Intelligent change detection significantly reduces cloud costs and deployment time in multi-service architectures.

5. **CloudFront Configuration**: Managed caching policies are preferred over custom policies for standard use cases. Always update OAuth redirects when adding CDN layers.

6. **Observability First**: Implementing comprehensive monitoring early prevents debugging delays and enables proactive issue resolution.

## Breaking Changes

### [1.0.0]

- **Image Tags**: ECS task definitions now use `:latest` tag instead of commit SHA
  - **Migration**: No action required. Pipeline handles both tags.
  - **Impact**: Ensures images are always available for deployment

- **OAuth URLs**: Updated from ALB to CloudFront domain
  - **Migration**: Update Google OAuth console with new redirect URLs
  - **Impact**: Fixes 404 errors on OAuth callbacks

- **RabbitMQ User**: Changed from root to `999:999`
  - **Migration**: Recreate RabbitMQ containers
  - **Impact**: Fixes Erlang cookie permission issues

## Deprecations

### [1.0.0]

- **OpenAI API**: Replaced with Google API
  - **Removed**: `OPENAI_API_KEY` environment variable
  - **Added**: `GOOGLE_API_KEY` secret in Secrets Manager
  - **Timeline**: Removed in Sprint 3

- **ECS Health Checks**: Removed curl-based health checks
  - **Reason**: curl not available in containers
  - **Alternative**: Using ALB health checks
  - **Timeline**: Removed in Sprint 3

## Contributors

- DevOps Team - Infrastructure and CI/CD
- Backend Team - Microservices architecture
- Frontend Team - Angular application
- QA Team - Testing and quality assurance

## References

- [Sprint 3 Report](../docs/sprint-3-report.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [DevOps Guide](DEVOPS.md)
- [GitHub Repository](https://github.com/AmaliTech-Training-Academy/skill-tracker-devops)

---

**Maintained By**: DevOps Team
**Last Updated**: November 28, 2025
**Next Review**: Sprint 4 Completion
