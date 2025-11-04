# Observability Module

This module deploys a complete observability stack with Prometheus and Grafana on EC2, integrated with AWS Distro for OpenTelemetry (ADOT) sidecars for ECS services.

## Architecture

```
ECS Services (with ADOT Sidecars)
    │
    │ Metrics (Prometheus Remote Write)
    ▼
EC2 Instance
    ├── Prometheus (Port 9090)
    │   └── Data: /mnt/prometheus-data (50GB EBS)
    │
    └── Grafana (Port 3000)
        └── Data: /var/lib/grafana
```

## Features

- ✅ **Prometheus** for metrics collection and storage
- ✅ **Grafana** for visualization and dashboards
- ✅ **ADOT Sidecars** for automatic metrics collection from Spring Boot services
- ✅ **ECS Service Discovery** for automatic target discovery
- ✅ **CloudWatch Integration** for hybrid monitoring
- ✅ **Persistent Storage** with dedicated EBS volume
- ✅ **Elastic IP** for stable access
- ✅ **IAM Roles** with least-privilege permissions

## Components

### EC2 Instance
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM) - default, can upgrade to t3.large
- **OS**: Amazon Linux 2023
- **Root Volume**: 20GB (system)
- **Data Volume**: 50GB (Prometheus data)
- **Network**: Public subnet with Elastic IP

### Prometheus
- **Version**: 2.48.0
- **Retention**: 30 days
- **Scrape Interval**: 15 seconds
- **Storage**: Dedicated EBS volume
- **Features**:
  - ECS service discovery
  - Remote write endpoint for ADOT
  - Self-monitoring
  - Dynamic target discovery

### Grafana
- **Version**: 10.2.2 (Docker)
- **Default Credentials**: admin/admin
- **Datasources**:
  - Prometheus (pre-configured)
  - CloudWatch (optional)
- **Plugins**:
  - Clock panel
  - Simple JSON datasource
  - Pie chart panel

### ADOT Collector
- **Image**: public.ecr.aws/aws-observability/aws-otel-collector:v0.35.0
- **Resources**: 256 CPU, 512MB Memory
- **Features**:
  - Scrapes Spring Boot Actuator `/actuator/prometheus`
  - Auto-discovers JVM metrics
  - Forwards to Prometheus via remote write
  - ECS metadata enrichment
  - Health check endpoint

## Usage

### 1. Add Module to Environment

```hcl
module "observability" {
  source = "../../modules/observability"
  
  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = module.networking.vpc_id
  vpc_cidr         = module.networking.vpc_cidr
  public_subnet_id = module.networking.public_subnet_ids[0]
  ecs_cluster_name = module.ecs.cluster_name
  aws_region       = var.aws_region
  
  # Optional: Customize instance (defaults to t3.medium)
  instance_type          = "t3.medium"  # or "t3.large" for more resources
  prometheus_volume_size = 50
  create_elastic_ip      = true
  
  # Security: Restrict access in production
  allowed_cidr_blocks = ["0.0.0.0/0"]  # Change to your IP
  
  tags = local.common_tags
}
```

### 2. Add ADOT Sidecar to ECS Services

The module outputs an ADOT container definition template. Add it to your task definitions:

```hcl
# In your app-services module or task definition
resource "aws_ecs_task_definition" "service" {
  family = "my-service"
  
  container_definitions = jsonencode([
    {
      # Your main application container
      name  = "app"
      image = "..."
      # ... other config
    },
    {
      # ADOT Sidecar
      name      = "aws-otel-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:v0.35.0"
      essential = false
      cpu       = 256
      memory    = 512
      
      environment = [
        { name = "SERVICE_NAME", value = "my-service" },
        { name = "ENVIRONMENT", value = var.environment },
        { name = "PROMETHEUS_ENDPOINT", value = module.observability.prometheus_endpoint },
        # ... other env vars from module output
      ]
      
      # ... rest of ADOT config from module output
    }
  ])
}
```

### 3. Update IAM Roles

Add CloudWatch permissions to ECS task execution role:

```hcl
# In your IAM module
resource "aws_iam_role_policy_attachment" "ecs_task_execution_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
```

### 4. Enable Spring Boot Actuator

Ensure your Spring Boot services expose Prometheus metrics:

```yaml
# application.yml (in config-server repository)
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
  metrics:
    export:
      prometheus:
        enabled: true
```

**Note**: This is already configured if you're using Spring Boot Actuator.

## Accessing the Stack

After deployment, you'll get outputs:

```bash
# Get outputs
terraform output -module=observability

# Access Grafana
http://<elastic-ip>:3000
# Default credentials: admin/admin

# Access Prometheus
http://<elastic-ip>:9090
```

## Security Groups

The module creates a security group with:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 3000 | TCP | allowed_cidr_blocks | Grafana Web UI |
| 9090 | TCP | allowed_cidr_blocks | Prometheus Web UI |
| 9090 | TCP | VPC CIDR | Prometheus Remote Write (ADOT) |
| 22 | TCP | allowed_cidr_blocks | SSH access |

## Monitoring

### Service Discovery

The module includes automatic ECS service discovery:
- Cron job runs every minute
- Discovers ECS tasks with ADOT sidecars
- Updates Prometheus targets dynamically
- No manual configuration needed

### Health Checks

Built-in health check script:
```bash
ssh ec2-user@<instance-ip>
sudo /usr/local/bin/health-check.sh
```

### Logs

- **User Data**: `/var/log/user-data.log`
- **ADOT Discovery**: `/var/log/adot-discovery.log`
- **Prometheus**: `journalctl -u prometheus -f`
- **Grafana**: `docker logs -f grafana`

## Dashboards

### Pre-configured Metrics

ADOT automatically collects:
- JVM metrics (heap, threads, GC)
- Process metrics (CPU, memory)
- System metrics (disk, network)
- Spring Boot metrics (HTTP requests, DB connections)
- Custom application metrics

### Sample Queries

```promql
# Request rate per service
rate(http_server_requests_seconds_count[5m])

# JVM heap usage
jvm_memory_used_bytes{area="heap"}

# Service availability
up{job="adot-collector"}

# Response time (p95)
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))
```

## Troubleshooting

### ADOT Sidecar Not Sending Metrics

1. Check ADOT container logs:
```bash
aws ecs describe-tasks --cluster <cluster> --tasks <task-arn>
aws logs tail /aws/ecs/<project>-<env>-adot --follow
```

2. Verify health check:
```bash
# From within ECS task
curl http://localhost:13133/
```

3. Check Prometheus endpoint:
```bash
# From app container
curl http://localhost:8080/actuator/prometheus
```

### Prometheus Not Discovering Targets

1. Check discovery script:
```bash
ssh ec2-user@<instance-ip>
cat /etc/prometheus/targets/ecs-tasks.json
```

2. Verify IAM permissions:
```bash
aws ecs list-tasks --cluster <cluster>
```

3. Check Prometheus targets:
```
http://<instance-ip>:9090/targets
```

### Grafana Not Showing Data

1. Verify Prometheus datasource:
   - Go to Configuration → Data Sources
   - Test connection

2. Check Prometheus is receiving data:
```
http://<instance-ip>:9090/graph
```

3. Verify time range in Grafana

## Cost Estimation

### Dev Environment (t3.medium)
- EC2 t3.medium: ~$30/month
- EBS 50GB gp3: ~$5/month
- EBS 20GB gp3 (root): ~$2/month
- Elastic IP: Free (when attached)
- **Total**: ~$37/month

### Dev Environment (t3.large - if you need more resources)
- EC2 t3.large: ~$60/month
- EBS 50GB gp3: ~$5/month
- EBS 20GB gp3 (root): ~$2/month
- Elastic IP: Free (when attached)
- **Total**: ~$67/month

### Scaling Recommendations
- **t3.medium**: Good for 1-5 services, dev/test environments
- **t3.large**: Recommended for 6-15 services, staging
- **t3.xlarge**: Production with 15+ services or high cardinality metrics
- **Managed Services**: Consider Amazon Managed Grafana/Prometheus for production

## Maintenance

### Backup Prometheus Data

```bash
# SSH to instance
ssh ec2-user@<instance-ip>

# Create snapshot
sudo tar -czf /tmp/prometheus-backup-$(date +%Y%m%d).tar.gz /mnt/prometheus-data

# Upload to S3
aws s3 cp /tmp/prometheus-backup-*.tar.gz s3://your-backup-bucket/
```

### Update Prometheus

```bash
# SSH to instance
sudo systemctl stop prometheus
cd /opt/prometheus
# Download new version
wget https://github.com/prometheus/prometheus/releases/download/vX.X.X/...
# Extract and replace
sudo systemctl start prometheus
```

### Update Grafana

```bash
docker stop grafana
docker rm grafana
docker pull grafana/grafana:latest
# Run with same volume mount
```

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | EC2 instance ID |
| `instance_public_ip` | Public IP address |
| `elastic_ip` | Elastic IP (if created) |
| `prometheus_url` | Prometheus web UI URL |
| `grafana_url` | Grafana web UI URL |
| `prometheus_endpoint` | Prometheus remote write endpoint for ADOT |
| `security_group_id` | Security group ID |

## Future Enhancements

- [ ] Add Loki for log aggregation
- [ ] Add Tempo for distributed tracing
- [ ] Add Alertmanager for alerting
- [ ] Add Thanos for long-term storage
- [ ] Pre-configured Grafana dashboards
- [ ] Automated backup to S3
- [ ] High availability setup
- [ ] TLS/SSL for web UIs
