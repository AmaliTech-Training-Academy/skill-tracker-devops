# Observability Stack - Quick Reference Card

## 🚀 Quick Deploy

```bash
# 1. Add to envs/dev/main.tf
module "observability" {
  source = "../../modules/observability"
  
  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = module.networking.vpc_id
  vpc_cidr         = module.networking.vpc_cidr
  public_subnet_id = module.networking.public_subnet_ids[0]
  ecs_cluster_name = module.ecs.cluster_name
  aws_region       = var.aws_region
  
  tags = local.common_tags
}

# 2. Deploy
cd infrastructure/envs/dev
terraform init
terraform apply

# 3. Get URLs
terraform output prometheus_url
terraform output grafana_url
```

## 📊 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://\<elastic-ip\>:3000 | admin / admin |
| Prometheus | http://\<elastic-ip\>:9090 | None |
| ADOT Health | http://localhost:13133 | From ECS task |

## 🔍 Useful Prometheus Queries

```promql
# Service availability
up{job="adot-collector"}

# Request rate per service
sum(rate(http_server_requests_seconds_count[5m])) by (service_name)

# Response time (p95)
histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket[5m])) by (service_name, le))

# Error rate
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) by (service_name)

# JVM heap usage
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100

# CPU usage
system_cpu_usage * 100

# Thread count
jvm_threads_live_threads

# GC time
rate(jvm_gc_pause_seconds_sum[5m])
```

## 🐛 Troubleshooting Commands

```bash
# SSH to monitoring instance
ssh ec2-user@<elastic-ip>

# Check Prometheus status
sudo systemctl status prometheus
sudo journalctl -u prometheus -f

# Check Grafana status
docker ps | grep grafana
docker logs -f grafana

# Check service discovery
cat /etc/prometheus/targets/ecs-tasks.json

# Manual discovery run
sudo /usr/local/bin/discover-adot-endpoints.sh

# Check ADOT logs from ECS
aws logs tail /aws/ecs/sdt-dev-adot --follow

# Verify Spring Boot metrics endpoint
curl http://localhost:8080/actuator/prometheus
```

## 📦 ADOT Sidecar Template

```json
{
  "name": "aws-otel-collector",
  "image": "public.ecr.aws/aws-observability/aws-otel-collector:v0.35.0",
  "essential": false,
  "cpu": 256,
  "memory": 512,
  "environment": [
    {"name": "SERVICE_NAME", "value": "my-service"},
    {"name": "SERVICE_PORT", "value": "8080"},
    {"name": "PROMETHEUS_ENDPOINT", "value": "http://<prometheus-ip>:9090/api/v1/write"}
  ],
  "healthCheck": {
    "command": ["CMD-SHELL", "wget --spider -q http://localhost:13133/ || exit 1"],
    "interval": 30,
    "timeout": 5,
    "retries": 3,
    "startPeriod": 60
  }
}
```

## 🔧 Common Tasks

### Add ADOT to a Service
1. Increase task CPU/Memory (add 256/512)
2. Add ADOT sidecar to container_definitions
3. Update task definition
4. Deploy service

### Create Custom Dashboard
1. Go to Grafana → Create → Dashboard
2. Add Panel → Select Prometheus datasource
3. Enter PromQL query
4. Configure visualization
5. Save dashboard

### Set Up Alerts
1. Create alert rules in Prometheus
2. Configure Alertmanager
3. Add notification channels (Slack, email)
4. Test alerts

### Backup Prometheus Data
```bash
ssh ec2-user@<ip>
sudo tar -czf /tmp/prometheus-backup.tar.gz /mnt/prometheus-data
aws s3 cp /tmp/prometheus-backup.tar.gz s3://your-bucket/
```

## 💰 Cost

- **Dev**: ~$38/month (t3.medium + 50GB EBS)
- **Staging**: ~$67/month (t3.large + 50GB EBS)
- **Prod**: ~$120/month (t3.xlarge + 100GB EBS)

## 📚 Documentation

- Module README: `modules/observability/README.md`
- Integration Guide: `modules/observability/INTEGRATION_GUIDE.md`
- Deployment Summary: `modules/observability/DEPLOYMENT_SUMMARY.md`

## ⚡ Performance Tips

- Keep Prometheus retention at 30 days
- Use recording rules for complex queries
- Enable query caching in Grafana
- Monitor ADOT sidecar resource usage
- Use service discovery for dynamic targets

## 🔒 Security Checklist

- [ ] Restrict `allowed_cidr_blocks` to your IP
- [ ] Change Grafana admin password
- [ ] Enable HTTPS (use ALB with SSL)
- [ ] Use private subnet for production
- [ ] Enable Prometheus authentication
- [ ] Rotate IAM credentials regularly
- [ ] Enable CloudWatch Logs encryption

## 🎯 Success Metrics

- ✅ All services showing in Prometheus targets
- ✅ Metrics flowing to Grafana
- ✅ Dashboards displaying data
- ✅ ADOT sidecars healthy
- ✅ No performance impact on services
- ✅ Alerts configured and tested

## 🆘 Emergency Contacts

- Prometheus not scraping: Check security groups
- Grafana down: `docker restart grafana`
- High costs: Reduce retention or instance size
- No metrics: Verify ADOT sidecar logs
