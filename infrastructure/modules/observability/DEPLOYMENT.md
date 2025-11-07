# Hybrid Monitoring Deployment Guide

## Prerequisites

### 1. Enable CloudWatch Billing Metrics
**Required for cost monitoring dashboard**

1. Log in to AWS Console as root or billing admin
2. Navigate to **Billing → Billing Preferences**
3. Check **Receive Billing Alerts**
4. Click **Save preferences**
5. Wait 24 hours for first data points

> **Note**: Billing metrics only available in `us-east-1` region

### 2. Verify Prometheus Targets
Ensure ADOT sidecars are running and exposing metrics:
```bash
# From Prometheus EC2 or any instance with access to ECS tasks
curl -s http://api-gateway.dev.sdt.local:8889/metrics | head
curl -s http://user-service.dev.sdt.local:8889/metrics | head
```

## Deployment Steps

### Step 1: Apply Observability Module

```bash
cd infrastructure/envs/dev

# Plan changes
terraform plan -target=module.observability

# Review:
# - New IAM role and instance profile
# - Grafana provider configuration
# - 2 datasources (Prometheus, CloudWatch)
# - 3 dashboards (Service Overview, Infrastructure, Cost)

# Apply
terraform apply -target=module.observability
```

**Expected output:**
```
Apply complete! Resources: 8 added, 1 changed, 0 destroyed.

Outputs:
grafana_url = "http://54.XXX.XXX.XXX:3000"
prometheus_url = "http://54.XXX.XXX.XXX:9090"
```

### Step 2: Wait for Instance Initialization
The user-data script takes ~3-5 minutes to:
- Install Docker
- Pull Prometheus and Grafana images
- Start containers on observability-net network
- Provision datasources

Check status:
```bash
# SSH to instance (if SSH enabled)
ssh -i your-key.pem ec2-user@<public-ip>

# Check containers
sudo docker ps

# Expected output:
# CONTAINER ID   IMAGE                    STATUS
# abc123...      grafana/grafana:latest   Up 2 minutes
# def456...      prom/prometheus:latest   Up 2 minutes

# Check logs
sudo docker logs grafana
sudo docker logs prometheus
```

### Step 3: Access Grafana

1. Open browser: `http://<public-ip>:3000`
2. Login:
   - Username: `admin`
   - Password: (from `grafana_admin_password` variable)
3. You should see the home page

### Step 4: Verify Datasources

**Prometheus:**
1. Grafana → Connections → Data sources → Prometheus
2. Click **Save & test**
3. Should see: "Data source is working"

**CloudWatch:**
1. Grafana → Connections → Data sources → CloudWatch
2. Click **Save & test**
3. Should see: "Data source is working"

If CloudWatch fails:
- Check IAM role attached to EC2 instance
- Verify instance profile has CloudWatch read permissions

### Step 5: Verify Dashboards

Navigate to Dashboards → Browse. You should see:

1. **SDT - Service Overview** (Prometheus)
   - 11 panels showing application metrics
   - Variable: $service (select services)
   
2. **SDT - Infrastructure Overview** (CloudWatch)
   - 10 panels showing AWS infrastructure metrics
   - ECS, RDS, ALB, NAT Gateway
   
3. **SDT - Cost Monitoring** (CloudWatch Billing)
   - 8 panels showing cost breakdown
   - Total charges, per-service costs, data transfer

### Step 6: Test Metrics

**Service Overview Dashboard:**
1. Select "All" in $service dropdown
2. Check "Service Availability" panel → should show 1 for each service
3. Check "Requests per Second" → should show traffic
4. Check "JVM Heap" → should show memory usage

**Infrastructure Dashboard:**
1. Check "ECS Cluster CPU" → should show cluster metrics
2. Check "RDS Connections" → should show DB connections
3. Check "ALB Request Count" → should show load balancer traffic

**Cost Dashboard:**
1. Check "Estimated AWS Charges" → may show $0 if billing alerts not enabled
2. Wait 24h after enabling billing alerts for data

## Troubleshooting

### Dashboard shows "No data"

**Prometheus metrics missing:**
```bash
# Check Prometheus targets
curl http://<public-ip>:9090/targets

# All targets should be "UP"
# If DOWN, check ADOT sidecar logs in ECS
```

**CloudWatch metrics missing:**
```bash
# Verify IAM permissions
aws sts get-caller-identity

# Check CloudWatch metrics exist
aws cloudwatch list-metrics --namespace AWS/ECS --region eu-west-1
```

### Grafana provider error during apply

```
Error: Failed to create dashboard
```

**Solution:**
1. Wait for Grafana to fully start (3-5 min)
2. Re-run terraform apply
3. Or manually import dashboards from `dashboards/` directory

### Cost metrics showing $0

**Causes:**
- Billing alerts not enabled
- Less than 24h since enabling
- Metrics only in us-east-1

**Solution:**
1. Enable billing alerts in AWS Console
2. Wait 24 hours
3. Verify in CloudWatch console (us-east-1):
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Billing \
     --metric-name EstimatedCharges \
     --dimensions Name=Currency,Value=USD \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-12-31T23:59:59Z \
     --period 86400 \
     --statistics Maximum \
     --region us-east-1
   ```

### Prometheus data not persisting

Check volume mount:
```bash
ssh ec2-user@<public-ip>
sudo ls -la /opt/observability/prometheus/data
sudo docker inspect prometheus | grep -A 10 Mounts
```

Should see:
```
/opt/observability/prometheus/data:/prometheus
```

## Post-Deployment Configuration

### 1. Restrict Access (Production)

Update `envs/dev/main.tf`:
```hcl
module "observability" {
  # ...
  web_allowed_cidrs = ["YOUR_IP/32"]  # Your office/VPN IP
  ssh_allowed_cidrs = ["YOUR_IP/32"]  # Enable SSH if needed
}
```

### 2. Set Strong Password

Update `envs/dev/main.tf`:
```hcl
module "observability" {
  # ...
  grafana_admin_password = "YourSecurePassword123!"
}
```

Or use Secrets Manager:
```hcl
data "aws_secretsmanager_secret_version" "grafana_password" {
  secret_id = "sdt/dev/grafana-admin-password"
}

module "observability" {
  # ...
  grafana_admin_password = data.aws_secretsmanager_secret_version.grafana_password.secret_string
}
```

### 3. Add Alerting (Optional)

Edit `grafana_dashboards.tf` to add alert rules:
```hcl
alert = {
  name = "High Error Rate"
  conditions = [{
    evaluator = { type = "gt", params = [5] }
    query     = { refId = "A" }
    reducer   = { type = "avg" }
    type      = "query"
  }]
  executionErrorState = "alerting"
  frequency           = "60s"
  handler             = 1
  message             = "Error rate exceeded 5%!"
  noDataState         = "no_data"
}
```

### 4. Configure Notification Channels

In Grafana UI:
1. Alerting → Notification channels → New channel
2. Type: Slack, Email, PagerDuty, etc.
3. Configure webhook URL or SMTP settings
4. Test notification
5. Link to alert rules

### 5. Backup Dashboards

Export dashboards to version control:
```bash
# Export all dashboards
curl -u admin:password http://<public-ip>:3000/api/search | jq -r '.[] | .uid' | \
while read uid; do
  curl -u admin:password http://<public-ip>:3000/api/dashboards/uid/$uid | \
  jq '.dashboard' > "backup-$uid.json"
done
```

## Maintenance

### Update Dashboards

1. Edit `grafana_dashboards.tf` or JSON files
2. Run `terraform apply -target=module.observability`
3. Dashboards auto-update

### Increase Prometheus Retention

Edit `user-data.sh`:
```bash
--storage.tsdb.retention.time=30d \
--storage.tsdb.retention.size=20GB \
```

Then:
```bash
terraform taint module.observability.aws_instance.monitoring
terraform apply -target=module.observability
```

### Upgrade Grafana/Prometheus

Edit `user-data.sh`:
```bash
prom/prometheus:v2.48.0
grafana/grafana:10.2.0
```

Then recreate instance.

## Monitoring Checklist

- [ ] Billing alerts enabled in AWS Console
- [ ] All Prometheus targets showing "UP"
- [ ] Grafana datasources tested successfully
- [ ] Service Overview dashboard showing metrics
- [ ] Infrastructure dashboard showing AWS metrics
- [ ] Cost dashboard showing charges (after 24h)
- [ ] Access restricted to authorized IPs
- [ ] Strong admin password set
- [ ] Dashboards backed up to Git
- [ ] Alert notification channels configured
- [ ] Team trained on dashboard usage

## Next Steps

1. **Create custom dashboards** for specific services
2. **Set up alerting** for critical metrics
3. **Integrate with Slack** for notifications
4. **Add more services** to Prometheus scrape config
5. **Enable HTTPS** via ALB (production)
6. **Set up log aggregation** (CloudWatch Logs Insights)
7. **Create runbooks** for common alerts

## Support

For issues or questions:
- Check logs: `sudo docker logs grafana` / `sudo docker logs prometheus`
- Review Terraform state: `terraform state show module.observability.aws_instance.monitoring`
- Consult README.md for architecture details
