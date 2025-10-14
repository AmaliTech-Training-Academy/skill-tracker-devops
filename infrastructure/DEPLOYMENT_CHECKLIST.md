# Deployment Checklist

Use this checklist when deploying infrastructure to each environment.

## Pre-Deployment

### AWS Account Setup
- [ ] AWS account created
- [ ] AWS CLI configured with credentials
- [ ] IAM user/role has necessary permissions
- [ ] MFA enabled on AWS account (production)
- [ ] Billing alerts configured

### Local Environment
- [ ] Terraform >= 1.5.0 installed
- [ ] AWS CLI >= 2.0 installed
- [ ] Git repository cloned
- [ ] SSH keys configured (if using private repos)

### Repository Setup
- [ ] `.gitignore` includes `*.tfvars`
- [ ] No secrets committed to git
- [ ] Branch protection rules set (production)

## Backend Setup

### Terraform State Backend
- [ ] S3 bucket created: `sdt-terraform-state`
- [ ] S3 bucket versioning enabled
- [ ] S3 bucket encryption enabled (AES-256)
- [ ] S3 public access blocked
- [ ] DynamoDB table created: `sdt-dev-locks`
- [ ] DynamoDB table created: `sdt-staging-locks`
- [ ] DynamoDB table created: `sdt-production-locks`

```bash
make setup-backend ENV=dev
make setup-backend ENV=staging
make setup-backend ENV=production
```

## Environment Configuration

### Variables File
- [ ] Copy `terraform.tfvars.example` to `envs/<env>/terraform.tfvars`
- [ ] Update `aws_region`
- [ ] Update `vpc_cidr` (unique per environment)
- [ ] Update `public_subnet_cidrs`
- [ ] Update `private_subnet_cidrs`
- [ ] Update `availability_zones`
- [ ] Update `db_name`
- [ ] Update `cors_allowed_origins`
- [ ] Update `alarm_email_endpoints`
- [ ] Update `amplify_repository_url`
- [ ] Set `github_access_token` (if private repo)
- [ ] Update `custom_domain_name` (production only)

### Feature Flags
- [ ] Set `enable_nat_gateway` appropriately
- [ ] Set `enable_vpc_flow_logs` (staging/production)
- [ ] Set `enable_xray` (staging/production)

## Terraform Initialization

- [ ] Run `terraform init` in environment directory
- [ ] Review initialization output for errors
- [ ] Verify backend configuration loaded correctly

```bash
cd envs/dev
terraform init
```

## Planning Phase

- [ ] Run `terraform plan`
- [ ] Review all resources to be created
- [ ] Verify resource counts match expectations
- [ ] Check for unintended deletions
- [ ] Review security group rules
- [ ] Verify IAM policies
- [ ] Save plan output for review

```bash
terraform plan -out=tfplan
```

Expected resource counts:
- **Dev**: ~80-90 resources
- **Staging**: ~90-100 resources  
- **Production**: ~100-110 resources (includes read replica)

## Apply Phase

### Pre-Apply
- [ ] Stakeholders notified (staging/production)
- [ ] Maintenance window scheduled (production)
- [ ] Backup of existing infrastructure (if applicable)
- [ ] Rollback plan documented

### Apply
- [ ] Run `terraform apply`
- [ ] Monitor apply progress
- [ ] Document any errors or warnings
- [ ] Verify no failed resources

```bash
terraform apply tfplan
```

### Post-Apply
- [ ] Run `terraform output` and save results
- [ ] Verify all outputs populated correctly
- [ ] Document important values (endpoints, ARNs, etc.)

## Verification

### Networking
- [ ] VPC created with correct CIDR
- [ ] Public subnets created (2)
- [ ] Private subnets created (2)
- [ ] Internet Gateway attached
- [ ] NAT Gateways created (if enabled)
- [ ] Route tables configured correctly
- [ ] Security groups created

### Compute
- [ ] ECS cluster created
- [ ] ECR repositories created (4):
  - [ ] auth-service
  - [ ] content-service
  - [ ] submission-service
  - [ ] sandbox-runner
- [ ] CloudWatch log groups created
- [ ] ALB created and healthy
- [ ] Target groups created

### Database
- [ ] RDS instance created
- [ ] RDS in private subnets only
- [ ] RDS security group allows ECS access
- [ ] Database credentials in Secrets Manager
- [ ] Backup schedule configured
- [ ] Multi-AZ enabled (production)
- [ ] Read replica created (production)

### Storage
- [ ] S3 buckets created (3):
  - [ ] user-uploads
  - [ ] static-assets
  - [ ] app-logs
- [ ] Bucket encryption enabled
- [ ] Bucket versioning enabled (where applicable)
- [ ] Lifecycle policies configured

### Frontend
- [ ] Amplify app created
- [ ] Repository connected
- [ ] Branch configured
- [ ] Environment variables set
- [ ] Build settings correct

### Monitoring
- [ ] CloudWatch dashboards created
- [ ] CloudWatch alarms created
- [ ] SNS topic created
- [ ] Log groups created with retention policies
- [ ] VPC Flow Logs enabled (if configured)

### IAM
- [ ] ECS task execution role created
- [ ] ECS task role created
- [ ] Amplify role created
- [ ] Policies attached correctly
- [ ] Least privilege verified

## Testing

### Connectivity
- [ ] ALB health checks passing
- [ ] ECS tasks can reach RDS
- [ ] ECS tasks can reach S3
- [ ] NAT Gateway working (if enabled)

### Database
- [ ] Can connect to RDS endpoint
- [ ] Database name correct
- [ ] Credentials work from Secrets Manager
- [ ] Backup configured correctly

### Container Registry
- [ ] Can authenticate to ECR
- [ ] Can push test image
- [ ] Image scanning works

```bash
# Test ECR
make ecr-login
docker tag hello-world:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/auth-service:test
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/sdt/dev/auth-service:test
```

### Monitoring
- [ ] CloudWatch dashboards accessible
- [ ] Logs appearing in log groups
- [ ] Test alarm notification (optional)

## Security Audit

- [ ] No public subnets with compute resources
- [ ] RDS not publicly accessible
- [ ] S3 buckets not public
- [ ] Security groups follow least privilege
- [ ] Encryption at rest enabled
- [ ] Encryption in transit enforced
- [ ] Secrets in Secrets Manager (not hardcoded)
- [ ] IAM roles follow least privilege
- [ ] CloudTrail enabled (optional)

## Documentation

- [ ] Document all outputs in team wiki/docs
- [ ] Update runbook with new endpoints
- [ ] Document database connection details
- [ ] Share ECR repository URLs with team
- [ ] Document Amplify app URL
- [ ] Update architecture diagrams if needed

## Notification & Handoff

### Stakeholder Notification
- [ ] DevOps team notified
- [ ] Development team notified
- [ ] QA team notified (staging/production)
- [ ] Management notified (production)

### Information to Share
- [ ] ALB DNS name
- [ ] Amplify app URL
- [ ] ECR repository URLs
- [ ] RDS endpoint (secure channel)
- [ ] CloudWatch dashboard links
- [ ] Any issues or warnings

### SNS Alarm Subscriptions
- [ ] Team members subscribed to SNS topic
- [ ] Email confirmations completed
- [ ] Test alarm sent and received

## Cost Management

- [ ] Review AWS Cost Explorer
- [ ] Verify resources match expected costs
- [ ] Set up budget alerts
- [ ] Tag all resources correctly
- [ ] Schedule for cost review

Expected monthly costs:
- **Dev**: $50-80
- **Staging**: $150-250
- **Production**: $400-600

## Rollback Plan (if needed)

### If Apply Fails
1. Review error messages
2. Fix configuration issue
3. Re-run `terraform apply`

### If Resources Created But Broken
1. `terraform destroy` specific resources
2. Fix configuration
3. Re-apply

### If Complete Rollback Needed
```bash
terraform destroy
# Review what will be destroyed
# Confirm destruction
```

**WARNING**: Only destroy if absolutely necessary and after backing up data!

## Post-Deployment (24-48 hours)

- [ ] Monitor CloudWatch metrics
- [ ] Review CloudWatch logs
- [ ] Check for any alarms
- [ ] Verify auto-scaling working
- [ ] Check RDS performance metrics
- [ ] Review costs in billing dashboard
- [ ] Gather team feedback

## Production-Specific Checklist

### Additional Production Steps
- [ ] Change management ticket created
- [ ] Deployment window scheduled
- [ ] On-call engineer assigned
- [ ] Customer notification sent (if needed)
- [ ] Database backup verified before changes
- [ ] Rollback plan tested
- [ ] Post-deployment verification script ready

### Production Verification
- [ ] Multi-AZ RDS confirmed
- [ ] Read replica created and syncing
- [ ] Deletion protection enabled on RDS
- [ ] Multiple NAT Gateways deployed
- [ ] Enhanced monitoring enabled
- [ ] Performance Insights enabled
- [ ] VPC Flow Logs enabled
- [ ] X-Ray enabled
- [ ] Increased backup retention (30 days)
- [ ] Custom domain configured (if applicable)

## Sign-Off

- [ ] Infrastructure deployed successfully
- [ ] All checks passed
- [ ] Documentation updated
- [ ] Team notified

**Deployed By**: _________________  
**Date**: _________________  
**Environment**: _________________  
**Terraform Version**: _________________  
**Notes**: _________________
