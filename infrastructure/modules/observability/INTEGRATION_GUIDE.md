# Observability Module - Integration Guide

This guide shows how to integrate the observability module (Prometheus + Grafana + ADOT) into your existing infrastructure.

## Step 1: Add Module to Dev Environment

Edit `/infrastructure/envs/dev/main.tf` and add the observability module:

```hcl
# Add after the monitoring module (around line 215)

# Observability Module - Prometheus + Grafana + ADOT
module "observability" {
  source = "../../modules/observability"
  
  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = module.networking.vpc_id
  vpc_cidr         = module.networking.vpc_cidr
  public_subnet_id = module.networking.public_subnet_ids[0]
  ecs_cluster_name = module.ecs.cluster_name
  aws_region       = var.aws_region
  
  # Instance configuration
  instance_type          = "t3.large"
  prometheus_version     = "2.48.0"
  grafana_version        = "10.2.2"
  prometheus_volume_size = 50
  create_elastic_ip      = true
  
  # Security - IMPORTANT: Restrict this to your IP in production
  allowed_cidr_blocks = ["0.0.0.0/0"]
  
  tags = local.common_tags
  
  depends_on = [module.ecs, module.networking]
}
```

## Step 2: Add Outputs

Edit `/infrastructure/envs/dev/outputs.tf` and add:

```hcl
# Observability Outputs
output "prometheus_url" {
  description = "Prometheus web UI URL"
  value       = module.observability.prometheus_url
}

output "grafana_url" {
  description = "Grafana web UI URL"  
  value       = module.observability.grafana_url
}

output "grafana_credentials" {
  description = "Default Grafana credentials"
  value       = "Username: admin, Password: admin (change on first login)"
}

output "monitoring_instance_ip" {
  description = "Monitoring EC2 instance IP"
  value       = module.observability.elastic_ip
}
```

## Step 3: Update IAM Module for ADOT

The ADOT sidecars need permissions to write to CloudWatch Logs. Edit `/infrastructure/modules/iam/policies.tf`:

```hcl
# Add to ECS Task Execution Role policy (if not already present)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Add ADOT-specific permissions to ECS Task Role
resource "aws_iam_role_policy" "ecs_task_adot" {
  name = "ecs-task-adot-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Step 4: Add ADOT Sidecars to Services (Optional - Manual Approach)

If you want to manually add ADOT sidecars to specific services, edit the task definition in `/infrastructure/modules/app-services/task_definitions.tf`.

### Example: Add ADOT to API Gateway

```hcl
resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "${var.project_name}-${var.environment}-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"  # Increased for ADOT sidecar
  memory                   = "2048"  # Increased for ADOT sidecar
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      # Main application container
      name      = "api-gateway"
      image     = "${var.ecr_repository_urls["api-gateway"]}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        # ... existing environment variables ...
      ]

      logConfiguration = {
        # ... existing log configuration ...
      }

      healthCheck = {
        # ... existing health check ...
      }
    },
    {
      # ADOT Sidecar
      name      = "aws-otel-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:v0.35.0"
      essential = false
      cpu       = 256
      memory    = 512
      
      environment = [
        { name = "SERVICE_NAME", value = "api-gateway" },
        { name = "SERVICE_PORT", value = "8080" },
        { name = "ENVIRONMENT", value = var.environment },
        { name = "ECS_CLUSTER_NAME", value = var.ecs_cluster_name },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "PROJECT_NAME", value = var.project_name },
        { name = "PROMETHEUS_ENDPOINT", value = var.prometheus_endpoint }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/${var.project_name}-${var.environment}-adot"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot-api-gateway"
          "awslogs-create-group"  = "true"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "wget --spider -q http://localhost:13133/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      
      portMappings = [
        { containerPort = 4317, protocol = "tcp" },
        { containerPort = 13133, protocol = "tcp" }
      ]
    }
  ])

  tags = var.tags
}
```

## Step 5: Add Variable for Prometheus Endpoint

Edit `/infrastructure/modules/app-services/variables.tf`:

```hcl
variable "prometheus_endpoint" {
  description = "Prometheus remote write endpoint for ADOT"
  type        = string
  default     = ""
}
```

Then pass it from the dev environment in `/infrastructure/envs/dev/main.tf`:

```hcl
module "app_services" {
  source = "../../modules/app-services"
  
  # ... existing variables ...
  
  prometheus_endpoint = module.observability.prometheus_endpoint
  
  # ... rest of configuration ...
  
  depends_on = [module.observability]
}
```

## Step 6: Deploy the Infrastructure

```bash
cd infrastructure/envs/dev

# Initialize (if new module)
terraform init

# Plan to see what will be created
terraform plan

# Apply the changes
terraform apply
```

## Step 7: Verify Deployment

After deployment completes:

### 1. Get the URLs
```bash
terraform output prometheus_url
terraform output grafana_url
```

### 2. Access Grafana
- Open the Grafana URL in your browser
- Login with: `admin` / `admin`
- Change the password when prompted

### 3. Verify Prometheus Datasource
- Go to Configuration → Data Sources
- Click on "Prometheus"
- Click "Test" - should show "Data source is working"

### 4. Check Prometheus Targets
- Open the Prometheus URL
- Go to Status → Targets
- You should see:
  - `prometheus` (self-monitoring)
  - `adot-collectors` (when services with ADOT are deployed)

### 5. SSH to Monitoring Instance (Optional)
```bash
# Get the instance IP
INSTANCE_IP=$(terraform output -raw monitoring_instance_ip)

# SSH (if you have the key)
ssh ec2-user@$INSTANCE_IP

# Check Prometheus status
sudo systemctl status prometheus

# Check Grafana status
docker ps | grep grafana

# View ADOT discovery
cat /etc/prometheus/targets/ecs-tasks.json
```

## Step 8: Deploy Services with ADOT

After the monitoring stack is running, deploy your services:

```bash
# If using CI/CD pipeline
git push origin dev

# Or manually update ECS services
aws ecs update-service \
  --cluster sdt-dev-cluster \
  --service api-gateway \
  --force-new-deployment
```

## Step 9: View Metrics in Grafana

### Create Your First Dashboard

1. In Grafana, click "+" → "Dashboard"
2. Click "Add new panel"
3. In the query editor, try these queries:

**JVM Heap Usage:**
```promql
jvm_memory_used_bytes{area="heap"}
```

**HTTP Request Rate:**
```promql
rate(http_server_requests_seconds_count[5m])
```

**Service Availability:**
```promql
up{job="adot-collector"}
```

**Response Time (95th percentile):**
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))
```

## Troubleshooting

### ADOT Sidecar Not Starting

Check ECS task logs:
```bash
aws logs tail /aws/ecs/sdt-dev-adot --follow
```

### No Metrics in Prometheus

1. Check if ADOT can reach the app:
```bash
# From within the ECS task
curl http://localhost:8080/actuator/prometheus
```

2. Check Prometheus targets:
```
http://<prometheus-ip>:9090/targets
```

3. Verify service discovery:
```bash
ssh ec2-user@<instance-ip>
cat /etc/prometheus/targets/ecs-tasks.json
```

### Grafana Can't Connect to Prometheus

1. Check Prometheus is running:
```bash
curl http://localhost:9090/-/healthy
```

2. Check from Grafana container:
```bash
docker exec -it grafana curl http://localhost:9090/api/v1/query?query=up
```

## Cost Estimate

**Dev Environment:**
- EC2 t3.large: ~$60/month
- EBS 50GB: ~$5/month
- Data transfer: ~$5/month
- **Total: ~$70/month**

## Next Steps

1. ✅ Add ADOT sidecars to all services
2. ✅ Create custom Grafana dashboards
3. ✅ Set up alerting in Prometheus
4. ✅ Configure Slack notifications
5. ✅ Add Loki for log aggregation (Phase 2)
6. ✅ Add Tempo for distributed tracing (Phase 3)

## Security Recommendations

### For Production:

1. **Restrict Access:**
```hcl
allowed_cidr_blocks = ["YOUR_OFFICE_IP/32"]
```

2. **Enable TLS:**
- Use Application Load Balancer with SSL certificate
- Configure Grafana with HTTPS

3. **Change Default Passwords:**
- Grafana admin password
- Add authentication to Prometheus

4. **Use Private Subnet:**
- Move monitoring instance to private subnet
- Access via VPN or bastion host

5. **Enable Backup:**
- Snapshot Prometheus data volume
- Backup Grafana dashboards to Git
