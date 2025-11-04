#!/bin/bash
set -e

# Update system
dnf update -y

# Install dependencies
dnf install -y wget tar gzip docker git

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create directories
mkdir -p /opt/prometheus /opt/grafana /var/lib/prometheus /var/lib/grafana
mkdir -p /etc/prometheus /etc/grafana

# Format and mount Prometheus data volume
if [ ! -d "/mnt/prometheus-data" ]; then
  mkfs -t ext4 /dev/nvme1n1
  mkdir -p /mnt/prometheus-data
  mount /dev/nvme1n1 /mnt/prometheus-data
  echo '/dev/nvme1n1 /mnt/prometheus-data ext4 defaults,nofail 0 2' >> /etc/fstab
fi

# Download and install Prometheus
cd /opt/prometheus
wget https://github.com/prometheus/prometheus/releases/download/v${prometheus_version}/prometheus-${prometheus_version}.linux-amd64.tar.gz
tar xvfz prometheus-${prometheus_version}.linux-amd64.tar.gz
mv prometheus-${prometheus_version}.linux-amd64/* .
rm -rf prometheus-${prometheus_version}.linux-amd64*

# Create Prometheus configuration
cat > /etc/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: '${ecs_cluster_name}'
    environment: '${environment}'

# Alertmanager configuration (optional)
# alerting:
#   alertmanagers:
#     - static_configs:
#         - targets: ['localhost:9093']

# Scrape configurations
scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # ECS Service Discovery via EC2
  - job_name: 'ecs-tasks'
    ec2_sd_configs:
      - region: ${aws_region}
        port: 9404
        filters:
          - name: tag:aws:ecs:cluster-name
            values: ['${ecs_cluster_name}']
    
    relabel_configs:
      # Extract task metadata
      - source_labels: [__meta_ec2_tag_Name]
        target_label: task_name
      - source_labels: [__meta_ec2_tag_aws_ecs_service_name]
        target_label: service_name
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
        replacement: '$1:9404'

  # ADOT Collector endpoints (will be added dynamically)
  - job_name: 'adot-collectors'
    file_sd_configs:
      - files:
          - '/etc/prometheus/targets/*.json'
        refresh_interval: 30s

  # CloudWatch Exporter (optional)
  - job_name: 'cloudwatch'
    static_configs:
      - targets: ['localhost:9106']

# Remote write configuration (for long-term storage)
# remote_write:
#   - url: http://thanos-receiver:19291/api/v1/receive
EOF

# Create Prometheus systemd service
cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/opt/prometheus/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/mnt/prometheus-data \
  --storage.tsdb.retention.time=30d \
  --web.console.templates=/opt/prometheus/consoles \
  --web.console.libraries=/opt/prometheus/console_libraries \
  --web.enable-lifecycle \
  --web.enable-admin-api

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start Prometheus
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

# Install Grafana using Docker
docker run -d \
  --name=grafana \
  --restart=always \
  -p 3000:3000 \
  -v /var/lib/grafana:/var/lib/grafana \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,grafana-piechart-panel" \
  -e "GF_SERVER_ROOT_URL=http://localhost:3000" \
  grafana/grafana:${grafana_version}

# Wait for Grafana to start
sleep 30

# Configure Grafana datasources
cat > /tmp/datasource.json <<'EOF'
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://localhost:9090",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "timeInterval": "15s"
  }
}
EOF

# Add Prometheus datasource to Grafana
curl -X POST -H "Content-Type: application/json" \
  -d @/tmp/datasource.json \
  http://admin:admin@localhost:3000/api/datasources

# Create directory for dynamic service discovery targets
mkdir -p /etc/prometheus/targets

# Create a script to discover ADOT endpoints
cat > /usr/local/bin/discover-adot-endpoints.sh <<'SCRIPT'
#!/bin/bash
# This script discovers ECS tasks with ADOT sidecars and creates Prometheus targets

AWS_REGION="${aws_region}"
CLUSTER_NAME="${ecs_cluster_name}"
OUTPUT_DIR="/etc/prometheus/targets"

# Get all tasks in the cluster
TASK_ARNS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --region $AWS_REGION --query 'taskArns[]' --output text)

if [ -z "$TASK_ARNS" ]; then
  echo "[]" > $OUTPUT_DIR/ecs-tasks.json
  exit 0
fi

# Describe tasks to get network details
TASKS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARNS --region $AWS_REGION)

# Parse and create Prometheus targets
echo "$TASKS" | jq -r '
  [
    .tasks[] | 
    select(.containers[] | select(.name == "aws-otel-collector")) |
    {
      targets: [
        (.attachments[] | 
         select(.type == "ElasticNetworkInterface") | 
         .details[] | 
         select(.name == "privateIPv4Address") | 
         .value) + ":4317"
      ],
      labels: {
        job: "adot-collector",
        task_arn: .taskArn,
        task_definition: (.taskDefinitionArn | split("/") | .[-1]),
        cluster: "${ecs_cluster_name}",
        environment: "${environment}"
      }
    }
  ]
' > $OUTPUT_DIR/ecs-tasks.json

SCRIPT

chmod +x /usr/local/bin/discover-adot-endpoints.sh

# Create cron job to run discovery every minute
cat > /etc/cron.d/adot-discovery <<'EOF'
* * * * * root /usr/local/bin/discover-adot-endpoints.sh >> /var/log/adot-discovery.log 2>&1
EOF

# Run discovery immediately
/usr/local/bin/discover-adot-endpoints.sh

# Create health check script
cat > /usr/local/bin/health-check.sh <<'EOF'
#!/bin/bash
# Health check for monitoring services

PROMETHEUS_STATUS=$(systemctl is-active prometheus)
GRAFANA_STATUS=$(docker inspect -f '{{.State.Running}}' grafana 2>/dev/null || echo "false")

if [ "$PROMETHEUS_STATUS" = "active" ] && [ "$GRAFANA_STATUS" = "true" ]; then
  echo "OK: All monitoring services running"
  exit 0
else
  echo "ERROR: Prometheus=$PROMETHEUS_STATUS, Grafana=$GRAFANA_STATUS"
  exit 1
fi
EOF

chmod +x /usr/local/bin/health-check.sh

# Log completion
echo "Monitoring stack installation completed at $(date)" >> /var/log/user-data.log
echo "Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090" >> /var/log/user-data.log
echo "Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000" >> /var/log/user-data.log
echo "Default Grafana credentials: admin/admin" >> /var/log/user-data.log
