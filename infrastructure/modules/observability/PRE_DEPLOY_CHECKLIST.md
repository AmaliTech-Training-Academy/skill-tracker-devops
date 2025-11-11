# Pre-Deployment Checklist

## ✅ Before You Deploy

### 1. AWS Billing Alerts (Required for Cost Dashboard)
- [ ] Log in to AWS Console as root or billing admin
- [ ] Navigate to **Billing → Billing Preferences**
- [ ] Check **✓ Receive Billing Alerts**
- [ ] Click **Save preferences**
- [ ] **Note**: Cost metrics will appear after 24 hours

### 2. Verify Current Infrastructure
```bash
cd infrastructure/envs/dev

# Check current state
terraform state list | grep -E "(networking|ecs|rds)"

# Ensure core infrastructure is deployed
# Expected: VPC, subnets, ECS cluster, RDS, etc.
```

### 3. Verify ADOT Sidecars (Prometheus Targets)
Check that your ECS services have ADOT sidecars exposing metrics:
```bash
# List ECS services
aws ecs list-services --cluster sdt-dev-cluster --region eu-west-1

# Check task definition for ADOT sidecar
aws ecs describe-task-definition \
  --task-definition sdt-dev-api-gateway \
  --region eu-west-1 | jq '.taskDefinition.containerDefinitions[] | select(.name | contains("adot"))'
```

### 4. Review Configuration
Check `envs/dev/main.tf` observability module:
```hcl
module "observability" {
  grafana_admin_password = "admin"  # ⚠️ Change in production!
  web_allowed_cidrs      = ["0.0.0.0/0"]  # ⚠️ Restrict in production!
  ssh_allowed_cidrs      = []  # SSH disabled (good)
}
```

### 5. Check Terraform State
```bash
# Ensure state is accessible
terraform state list

# Check for state lock
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"sdt-dev-terraform-state/terraform.tfstate-md5"}}' \
  --region eu-west-1 2>/dev/null || echo "No lock found (good)"
```

### 6. Verify AWS Credentials
```bash
# Check current AWS identity
aws sts get-caller-identity

# Verify region
aws configure get region
# Should be: eu-west-1
```

### 7. Estimate Costs
- **EC2 t3.small**: ~$15/month
- **EBS (if added)**: ~$3/month
- **Data transfer**: ~$2/month
- **Total**: ~$20/month for dev

---

## 🚀 Deployment Commands

### Option 1: Deploy Observability Only (Recommended First Time)
```bash
cd infrastructure/envs/dev

# Plan
terraform plan -target=module.observability

# Review output carefully
# Expected: 8-10 new resources

# Apply
terraform apply -target=module.observability
```

### Option 2: Deploy Everything (If Fresh Environment)
```bash
cd infrastructure/envs/dev

# Plan
terraform plan

# Apply
terraform apply
```

---

## ⏱️ Expected Timeline

1. **Terraform Apply**: 2-3 minutes
   - EC2 instance creation
   - IAM role/profile
   - Security group
   - Grafana provider setup

2. **User Data Script**: 3-5 minutes
   - Docker installation
   - Image pulls (Prometheus, Grafana)
   - Container startup
   - Network configuration

3. **Dashboard Provisioning**: 1-2 minutes
   - Grafana datasources
   - Dashboard creation via Terraform

**Total**: ~10 minutes

---

## 🔍 Post-Deployment Verification

### 1. Check Terraform Output
```bash
terraform output | grep observability
```

Expected:
```
grafana_url = "http://54.XXX.XXX.XXX:3000"
prometheus_url = "http://54.XXX.XXX.XXX:9090"
```

### 2. Wait for User Data Completion
```bash
# Get instance ID
INSTANCE_ID=$(terraform output -json | jq -r '.observability_instance_id.value')

# Check instance status
aws ec2 describe-instance-status \
  --instance-ids $INSTANCE_ID \
  --region eu-west-1

# Check user-data logs (if SSH enabled)
# ssh -i your-key.pem ec2-user@<public-ip>
# sudo tail -f /var/log/cloud-init-output.log
```

### 3. Test Prometheus
```bash
# Get public IP
PUBLIC_IP=$(terraform output -json | jq -r '.observability_instance_public_ip.value')

# Check Prometheus
curl -s http://$PUBLIC_IP:9090/-/healthy
# Expected: Prometheus is Healthy.

# Check targets
curl -s http://$PUBLIC_IP:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

### 4. Test Grafana
```bash
# Check Grafana
curl -s http://$PUBLIC_IP:3000/api/health
# Expected: {"database":"ok","version":"..."}

# Login via browser
open http://$PUBLIC_IP:3000
# Username: admin
# Password: admin (or your configured password)
```

### 5. Verify Dashboards
In Grafana UI:
- [ ] Navigate to **Dashboards → Browse**
- [ ] See 3 dashboards:
  - SDT - Service Overview
  - SDT - Infrastructure Overview
  - SDT - Cost Monitoring
- [ ] Open Service Overview → Select "All" services
- [ ] Check if metrics are showing

### 6. Verify Datasources
In Grafana UI:
- [ ] Navigate to **Connections → Data sources**
- [ ] See 2 datasources:
  - Prometheus (default)
  - CloudWatch
- [ ] Click each → **Save & test** → Should show "Data source is working"

---

## ⚠️ Troubleshooting

### No Grafana/Prometheus Response
```bash
# Check if instance is running
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].State.Name' \
  --region eu-west-1

# Check security group allows traffic
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=sdt-dev-observability-sg" \
  --region eu-west-1 | jq '.SecurityGroups[0].IpPermissions'
```

### Dashboards Not Created
```bash
# Check Terraform Grafana provider logs
terraform apply -target=module.observability 2>&1 | grep -i grafana

# If failed, wait 5 minutes and retry
terraform apply -target=module.observability
```

### Prometheus Shows No Targets
- Wait 5 minutes for service discovery to propagate
- Verify ADOT sidecars are running in ECS
- Check Prometheus config: `curl http://$PUBLIC_IP:9090/api/v1/status/config`

### CloudWatch Datasource Fails
```bash
# Check IAM instance profile
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].IamInstanceProfile' \
  --region eu-west-1

# Should show: sdt-dev-monitoring-profile
```

---

## 📋 Success Criteria

- [x] Terraform apply completed without errors
- [x] EC2 instance running
- [x] Prometheus accessible on port 9090
- [x] Grafana accessible on port 3000
- [x] 3 dashboards visible in Grafana
- [x] Prometheus datasource working
- [x] CloudWatch datasource working
- [x] Service Overview dashboard showing metrics
- [x] Infrastructure dashboard showing AWS metrics
- [x] Cost dashboard created (data after 24h)

---

## 🎯 Next Steps After Deployment

1. **Restrict Access** (Production)
   ```hcl
   web_allowed_cidrs = ["YOUR_IP/32"]
   ```

2. **Change Default Password**
   ```hcl
   grafana_admin_password = "SecurePassword123!"
   ```

3. **Add Alerts** (See DEPLOYMENT.md)

4. **Configure Slack Notifications**

5. **Add More Services** to Prometheus scrape config

6. **Star Dashboards** for quick access

7. **Export Dashboards** to Git for backup

---

## 🆘 Need Help?

- **Architecture**: `README.md`
- **Detailed Guide**: `DEPLOYMENT.md`
- **Quick Reference**: `QUICK_START.md`
- **Summary**: `SUMMARY.md`

**Ready to deploy?** Run the commands in the "Deployment Commands" section above! 🚀
