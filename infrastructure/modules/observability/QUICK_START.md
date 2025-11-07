# Monitoring Quick Start Guide

## 🚀 Deploy in 3 Steps

### 1. Enable Billing Alerts (One-time)
```
AWS Console → Billing → Billing Preferences → ✓ Receive Billing Alerts → Save
```

### 2. Deploy Monitoring Stack
```bash
cd infrastructure/envs/dev
terraform apply -target=module.observability
```

### 3. Access Dashboards
```
Grafana: http://<public-ip>:3000
Login: admin / <your-password>
```

---

## 📊 Dashboards

### Service Overview (Prometheus)
**What**: Application metrics from Spring Boot microservices  
**Use for**: Debugging, performance analysis, error tracking  
**Key panels**: RPS, Error rate, Latency p95/p99, JVM heap

### Infrastructure (CloudWatch)
**What**: AWS resource metrics  
**Use for**: Capacity planning, infrastructure health  
**Key panels**: ECS CPU/Memory, RDS connections, ALB traffic

### Cost Monitoring (CloudWatch Billing)
**What**: AWS spending breakdown  
**Use for**: Budget tracking, cost optimization  
**Key panels**: Total charges, per-service costs, data transfer

---

## 🔍 Common Queries

### Check Service Health
```
Grafana → Service Overview → Select service → Check "Availability" panel
```

### Find Slow Endpoints
```
Grafana → Service Overview → "Top 10 Endpoints by RPS" + "Latency p95"
```

### Identify Errors
```
Grafana → Service Overview → "Top 10 Errors by Endpoint"
```

### Check Infrastructure
```
Grafana → Infrastructure → ECS CPU/Memory + RDS Connections
```

### Review Costs
```
Grafana → Cost Monitoring → "Cost by Service"
```

---

## 🚨 Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Error Rate | > 2% | > 5% |
| Latency p95 | > 1s | > 3s |
| ECS CPU | > 70% | > 85% |
| RDS Connections | > 80 | > 95 |
| JVM Heap | > 75% | > 90% |

---

## 🛠️ Troubleshooting

### No data in Service Overview
```bash
# Check Prometheus targets
curl http://<public-ip>:9090/targets
# All should be "UP"
```

### No data in Infrastructure
```bash
# Verify IAM role
aws sts get-caller-identity
# Should show monitoring role
```

### Cost shows $0
- Wait 24h after enabling billing alerts
- Metrics only in us-east-1

---

## 📞 Quick Links

- **Grafana**: http://<public-ip>:3000
- **Prometheus**: http://<public-ip>:9090
- **Docs**: `infrastructure/modules/observability/README.md`
- **Deployment**: `infrastructure/modules/observability/DEPLOYMENT.md`

---

## 💡 Pro Tips

1. **Use $service variable** to filter specific services
2. **Set time range** to "Last 15m" for real-time debugging
3. **Star dashboards** for quick access
4. **Export dashboards** before making changes
5. **Check Prometheus first** for application issues
6. **Check CloudWatch** for infrastructure issues

---

**Need help?** Check `DEPLOYMENT.md` for detailed troubleshooting
