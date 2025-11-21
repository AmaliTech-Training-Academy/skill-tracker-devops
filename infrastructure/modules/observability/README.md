# SDT Observability Module

Hybrid monitoring solution combining **Prometheus** (application metrics) and **CloudWatch** (infrastructure metrics) with **Grafana** dashboards.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Grafana (Port 3000)                      │
│  ┌──────────────────┐           ┌──────────────────┐       │
│  │   Prometheus     │           │   CloudWatch     │       │
│  │   Datasource     │           │   Datasource     │       │
│  └────────┬─────────┘           └────────┬─────────┘       │
│           │                              │                  │
│  ┌────────▼──────────────────────────────▼─────────┐       │
│  │              3 Dashboards                        │       │
│  │  • Service Overview (Prometheus)                 │       │
│  │  • Infrastructure (CloudWatch)                   │       │
│  │  • Cost Monitoring (CloudWatch Billing)          │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
         │                                    │
         │                                    │
    ┌────▼────┐                         ┌────▼────┐
    │Prometheus│                         │CloudWatch│
    │(Port 9090│                         │   API    │
    └────┬────┘                         └────┬────┘
         │                                    │
    ┌────▼──────────────┐              ┌─────▼──────────┐
    │  ADOT Sidecars    │              │  AWS Resources │
    │  (Port 8889)      │              │  ECS, RDS, ALB │
    │  • api-gateway    │              │  NAT, VPC      │
    │  • config-server  │              └────────────────┘
    │  • discovery      │
    │  • user-service   │
    │  • task-service   │
    └───────────────────┘
```

## Components

### 1. Prometheus (Application Metrics)

- **Source**: ADOT sidecars scraping Spring Boot `/actuator/prometheus`
- **Metrics**:
  - HTTP requests (rate, count, duration)
  - Error rates (5xx)
  - Latency percentiles (p95, p99)
  - JVM (heap, GC, threads)
  - Hikari connection pool (if exposed)

### 2. CloudWatch (Infrastructure Metrics)

- **Source**: AWS native metrics
- **Metrics**:
  - **ECS**: CPU, memory utilization
  - **RDS**: CPU, connections, free storage
  - **ALB**: Request count, response time, 5xx errors
  - **NAT Gateway**: Bytes in/out
  - **VPC**: Network packets

### 3. Cost Monitoring

- **Source**: CloudWatch Billing metrics (us-east-1)
- **Metrics**:
  - Total estimated charges
  - Per-service costs (ECS, RDS, EC2, S3, Amplify)
  - Data transfer costs
  - NAT Gateway usage

## Dashboards

### Service Overview (Prometheus)

**File**: `dashboards/sdt-service-overview.json`

**Panels**:

- Service Availability (targets up)
- Requests per Second
- Error Rate (5xx %)
- Latency p95/p99
- HTTP Status Breakdown
- Top 10 Endpoints by RPS
- Top 10 Errors by Endpoint
- JVM Heap Used vs Max
- GC Pause Time
- JVM Threads Live

**Variable**: `$service` (multi-select, all services)

### Infrastructure Overview (CloudWatch)

**Managed by**: Terraform (`grafana_dashboards.tf`)

**Panels**:

- ECS Cluster CPU/Memory
- RDS CPU/Connections/Storage
- ALB Request Count/Response Time/5xx Errors
- NAT Gateway Bytes Out
- VPC Network Packets

### Cost Monitoring (CloudWatch Billing)

**Managed by**: Terraform (`grafana_dashboards.tf`)

**Panels**:

- Estimated AWS Charges (24h)
- ECS/RDS Service Charges
- Cost Trend (7 days)
- Cost by Service (ECS, RDS, EC2, S3, Amplify)
- Data Transfer Out
- NAT Gateway Data Processed

## Setup

### Prerequisites

1. Enable **CloudWatch billing metrics** in AWS Console:

   - Billing → Billing Preferences → Receive Billing Alerts → Enable
   - Metrics appear in us-east-1 only

2. Ensure IAM role has CloudWatch read permissions (auto-created by module)

### Deployment

```bash
cd infrastructure/envs/dev

# Plan
terraform plan -target=module.observability

# Apply
terraform apply -target=module.observability
```

### Access

- **Grafana**: http://<public-ip>:3000
  - User: `admin`
  - Password: (set in `grafana_admin_password` variable)
- **Prometheus**: http://<public-ip>:9090

### Import Dashboards

Dashboards are auto-provisioned via Terraform. If manual import needed:

1. Grafana → Dashboards → New → Import
2. Upload `dashboards/sdt-service-overview.json`
3. Select datasource: Prometheus

## Configuration

### Variables

```hcl
module "observability" {
  source = "../../modules/observability"

  project_name                = "sdt"
  environment                 = "dev"
  aws_region                  = "eu-west-1"
  vpc_id                      = module.networking.vpc_id
  public_subnet_ids           = module.networking.public_subnet_ids
  service_discovery_namespace = "dev.sdt.local"
  adot_exporter_port          = 8889
  grafana_admin_password      = "your-secure-password"

  # Access control
  ssh_allowed_cidrs = []              # SSH disabled by default
  web_allowed_cidrs = ["0.0.0.0/0"]   # Restrict in production

  tags = local.common_tags
}
```

### Customize Dashboards

Edit `grafana_dashboards.tf` to:

- Add/remove panels
- Adjust thresholds (CPU > 80%, error rate > 5%)
- Change refresh intervals
- Add alert rules

## Terraform-Managed Resources

```hcl
# Datasources
grafana_data_source.prometheus
grafana_data_source.cloudwatch

# Dashboards
grafana_dashboard.service_overview
grafana_dashboard.infrastructure
grafana_dashboard.cost_monitoring
```

## Alerts (Future Enhancement)

Add embedded alerts in panels:

```hcl
alert = {
  name = "High Error Rate"
  conditions = [{
    evaluator = { type = "gt", params = [5] }
    query     = { refId = "A" }
    reducer   = { type = "avg" }
  }]
  frequency = "60s"
  message   = "Error rate > 5%"
}
```

## Persistence

### Prometheus Data

Add volume mount in `user-data.sh`:

```bash
-v /opt/observability/prometheus/data:/prometheus \
--storage.tsdb.retention.time=15d
```

### Grafana Data

Already persisted:

```bash
-v /opt/observability/grafana:/var/lib/grafana
```

## Troubleshooting

### Grafana can't reach Prometheus

- Ensure both containers on `observability-net` network
- Check datasource URL: `http://prometheus:9090`

### CloudWatch metrics missing

- Verify IAM role attached to EC2
- Check region (billing metrics only in us-east-1)
- Enable billing alerts in AWS Console

### Dashboard not auto-provisioned

- Check Terraform apply output for errors
- Verify Grafana provider auth
- Manual import: use JSON from `dashboards/`

### Cost metrics showing $0

- Enable billing alerts in AWS Console
- Wait 24h for first data points
- Metrics only in us-east-1

## Cost Optimization

- **Dev**: t3.small instance (~$15/month)
- **Staging**: t3.medium (~$30/month)
- **Production**: t3.large + EBS volume (~$60/month)

## Maintenance

- **Prometheus retention**: 15 days (configurable)
- **Grafana backups**: Export dashboards to JSON
- **Updates**: Rebuild instance with `user_data_replace_on_change = true`

# Cost Monitoring Dashboard

## Overview

The Cost Monitoring dashboard in Grafana displays AWS costs **excluding credits, refunds, and taxes** using a custom Lambda-based solution that fetches data from AWS Cost Explorer and publishes it to CloudWatch as custom metrics.

## Architecture

```
AWS Cost Explorer → Lambda (Daily) → CloudWatch Custom Metrics → Grafana Dashboard
```

### Components

1. **Lambda Function** ([cost_exporter.py](lambda/cost_exporter.py))

   - Runs daily at 00:00 UTC via EventBridge
   - Fetches cost data from AWS Cost Explorer API
   - Filters out credits, refunds, and taxes
   - Publishes metrics to CloudWatch namespace: `SDT/Costs`

2. **CloudWatch Custom Metrics**

   - `TotalCost`: Total AWS charges (excluding credits)
   - `ServiceCost`: Per-service costs with dimension `ServiceName`

3. **Grafana Dashboard** ([sdt-cost-monitoring.json](dashboards/sdt-cost-monitoring.json))
   - Displays cost data from CloudWatch custom metrics
   - Shows total costs and breakdown by service
   - Updates hourly (data refreshes daily via Lambda)

## Why This Solution?

The standard AWS CloudWatch Billing metrics (`AWS/Billing` namespace) include credits, which can make costs appear as $0 even when you have actual charges. The AWS Cost Explorer Console allows filtering out credits, but CloudWatch Billing metrics do not support this filtering.

Our solution:

- Uses the Cost Explorer API with filters to exclude credits, refunds, and taxes
- Publishes filtered cost data as custom CloudWatch metrics
- Provides accurate cost visibility in Grafana

## Metrics Published

### Total Cost Metric

- **Namespace**: `SDT/Costs`
- **Metric Name**: `TotalCost`
- **Dimensions**: `Project`, `Environment`
- **Statistic**: Maximum
- **Period**: 86400 seconds (1 day)

### Service Cost Metrics

- **Namespace**: `SDT/Costs`
- **Metric Name**: `ServiceCost`
- **Dimensions**: `Project`, `Environment`, `ServiceName`
- **Statistic**: Sum
- **Period**: 86400 seconds (1 day)

Service names are mapped to friendly names:

- `ECS` - Amazon Elastic Container Service
- `RDS` - Amazon Relational Database Service
- `EC2` - Amazon Elastic Compute Cloud
- `S3` - Amazon Simple Storage Service
- `Amplify` - AWS Amplify
- `VPC` - Amazon Virtual Private Cloud (NAT Gateway)
- `CloudWatch` - Amazon CloudWatch
- `Lambda` - AWS Lambda
- `CloudFront` - Amazon CloudFront

## IAM Permissions

The Lambda function requires the following permissions:

```json
{
  "ce:GetCostAndUsage",
  "ce:GetCostForecast",
  "cloudwatch:PutMetricData",
  "logs:CreateLogGroup",
  "logs:CreateLogStream",
  "logs:PutLogEvents"
}
```

## Manual Testing

To manually trigger the Lambda function and test the cost export:

```bash
aws lambda invoke \
  --function-name sdt-dev-cost-exporter \
  --region us-east-1 \
  --output text \
  response.json

cat response.json
```

Check CloudWatch Logs:

```bash
aws logs tail /aws/lambda/sdt-dev-cost-exporter --follow
```

Verify metrics were published:

```bash
aws cloudwatch list-metrics \
  --namespace "SDT/Costs" \
  --region us-east-1
```

## Troubleshooting

### Dashboard shows "No data"

1. **Check if Lambda has run**:

   ```bash
   aws logs tail /aws/lambda/sdt-dev-cost-exporter --since 1h
   ```

2. **Manually invoke Lambda**:

   ```bash
   aws lambda invoke --function-name sdt-dev-cost-exporter response.json
   ```

3. **Verify metrics in CloudWatch**:

   - Go to AWS Console → CloudWatch → Metrics
   - Search for namespace: `SDT/Costs`
   - Check if metrics exist

4. **Check IAM permissions**:
   - Ensure Lambda role has `ce:GetCostAndUsage` permission
   - Ensure Lambda role has `cloudwatch:PutMetricData` permission

### Dashboard shows $0 for all services

1. **Check Cost Explorer data**:

   - Go to AWS Console → Cost Explorer
   - Verify you have actual costs (excluding credits)
   - Ensure you're looking at the correct time period

2. **Check Lambda logs for errors**:
   ```bash
   aws logs tail /aws/lambda/sdt-dev-cost-exporter --since 24h | grep ERROR
   ```

### Lambda execution fails

1. **Check Lambda timeout**: Current timeout is 60 seconds (should be sufficient)
2. **Check Lambda logs for specific errors**:
   ```bash
   aws logs tail /aws/lambda/sdt-dev-cost-exporter --since 1h --follow
   ```

## Cost Considerations

- **Lambda**: Runs once daily, costs < $0.01/month
- **CloudWatch Custom Metrics**: ~10 metrics, costs ~$0.30/month
- **CloudWatch Logs**: Minimal, costs < $0.10/month
- **Total estimated cost**: < $0.50/month
