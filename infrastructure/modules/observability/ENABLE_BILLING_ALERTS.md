# Enable AWS Billing Alerts for Cost Dashboard

The **Cost Monitoring Dashboard** requires AWS Billing Alerts to be enabled before metrics will appear.

## ⚠️ Important Notes

1. **Only root user or IAM users with billing permissions can enable this**
2. **Metrics appear in `us-east-1` region only** (AWS Billing is global but metrics are in us-east-1)
3. **Takes 24 hours** after enabling for data to start appearing
4. **One-time setup** - applies to entire AWS account

---

## 📋 Step-by-Step Guide

### Step 1: Log in to AWS Console
- Use **root account** or IAM user with `aws-portal:ViewBilling` and `aws-portal:ModifyBilling` permissions
- Navigate to: https://console.aws.amazon.com/billing/

### Step 2: Enable Billing Alerts
1. Click **Billing Preferences** in the left sidebar
2. Scroll to **Alert preferences** section
3. Check the box: **✓ Receive Billing Alerts**
4. Click **Save preferences**

### Step 3: Wait for Metrics
- **First data point**: 24 hours after enabling
- **Full historical data**: Not available (only forward-looking)
- **Update frequency**: Once per day (24-hour intervals)

### Step 4: Verify in Grafana
After 24 hours:
1. Open Cost Monitoring Dashboard: http://YOUR_GRAFANA_IP:3000/d/sdt-cost-monitoring
2. Refresh the page (Cmd+Shift+R or Ctrl+Shift+F5)
3. You should see cost data appearing

---

## 🔍 Troubleshooting

### Still showing "No data" after 24 hours?

**Check 1: Verify billing alerts are enabled**
```bash
# This will show if billing metrics exist
aws cloudwatch list-metrics \
  --namespace AWS/Billing \
  --region us-east-1 \
  --query 'Metrics[?MetricName==`EstimatedCharges`]' \
  --output table
```

**Expected output:**
```
---------------------------------------------------------
|                     ListMetrics                       |
+-------------------------------------------------------+
||                      Dimensions                     ||
|+----------------+------------------------------------+|
||  Name          |  Value                             ||
|+----------------+------------------------------------+|
||  Currency      |  USD                               ||
|+----------------+------------------------------------+|
||                       Metrics                       ||
|+-----------------------------------------------------+|
||  MetricName    |  EstimatedCharges                  ||
||  Namespace     |  AWS/Billing                       ||
|+-----------------------------------------------------+|
```

**Check 2: Query actual metric data**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Billing \
  --metric-name EstimatedCharges \
  --dimensions Name=Currency,Value=USD \
  --start-time $(date -u -v-7d +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Maximum \
  --region us-east-1
```

**Check 3: Verify IAM permissions**
The monitoring EC2 instance needs CloudWatch read permissions (already configured):
```bash
# Check if instance has correct role
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw observability_instance_id) \
  --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' \
  --region eu-west-1
```

### Dashboard shows $0.00?

This is normal if:
- You just enabled billing alerts (wait 24 hours)
- Your account has no charges yet
- You're in AWS Free Tier with no usage

---

## 📊 What Metrics Are Available

Once enabled, you'll see:

### Total Charges
- **Metric**: `EstimatedCharges`
- **Dimension**: `Currency=USD`
- **Description**: Total AWS charges across all services

### Per-Service Charges
- **Metric**: `EstimatedCharges`
- **Dimensions**: `Currency=USD`, `ServiceName=<service>`
- **Services tracked**:
  - Amazon Elastic Container Service
  - Amazon Relational Database Service
  - Amazon Elastic Compute Cloud - Compute
  - Amazon Simple Storage Service
  - AWS Amplify
  - Amazon Virtual Private Cloud (NAT Gateway)
  - And more...

### Update Frequency
- **Period**: 24 hours (86400 seconds)
- **Statistic**: Maximum (cumulative charges)
- **Delay**: Up to 24 hours

---

## 💰 Cost Dashboard Panels

Your dashboard includes:

1. **Estimated AWS Charges** - Total monthly charges
2. **ECS Service Charges** - Fargate task costs
3. **RDS Charges** - Database instance costs
4. **Cost Trend (7 days)** - Historical cost graph
5. **Cost by Service** - Stacked area chart of all services
6. **EC2 Charges** - Monitoring instance costs
7. **S3 Charges** - Storage costs
8. **Amplify Charges** - Frontend hosting costs
9. **VPC/NAT Gateway Charges** - Network costs

---

## 🎯 Expected Costs (Dev Environment)

Based on your infrastructure:

| Service | Monthly Cost (Estimate) |
|---------|------------------------|
| **ECS Fargate** | $15-25 (12 services, 0.25 vCPU each) |
| **RDS db.t3.micro** | $12-15 (single AZ) |
| **NAT Gateway** | $32-40 (2 gateways, data transfer) |
| **EC2 t3.small** | $15 (monitoring instance) |
| **ALB** | $16-20 |
| **S3** | $1-3 (minimal storage) |
| **Amplify** | $0-5 (build minutes) |
| **CloudWatch** | $3-5 (logs, metrics) |
| **Secrets Manager** | $1-2 |
| **VPC** | $0 (no charge for VPC itself) |
| **Data Transfer** | $5-10 |
| **TOTAL** | **~$100-125/month** |

---

## 🔐 IAM Policy for Billing Access

If you need to grant billing access to an IAM user:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "aws-portal:ViewBilling",
        "aws-portal:ModifyBilling"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 📚 Additional Resources

- [AWS Billing and Cost Management](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html)
- [Monitoring Charges with CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html)
- [AWS Billing Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/billing-metricscollected.html)

---

## ✅ Quick Checklist

- [ ] Logged in as root or billing admin
- [ ] Enabled "Receive Billing Alerts" in Billing Preferences
- [ ] Waited 24 hours for first data point
- [ ] Verified metrics exist via AWS CLI
- [ ] Refreshed Grafana dashboard
- [ ] Cost data is now visible

**Need help?** Check the troubleshooting section above or contact your AWS administrator.
