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

## Security

- Restrict `web_allowed_cidrs` to your IP/VPN
- Use strong `grafana_admin_password`
- Consider ALB + HTTPS for Grafana in production
- IAM role follows least-privilege (read-only CloudWatch)

## Maintenance

- **Prometheus retention**: 15 days (configurable)
- **Grafana backups**: Export dashboards to JSON
- **Updates**: Rebuild instance with `user_data_replace_on_change = true`

## References

- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [CloudWatch Metrics Reference](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)
