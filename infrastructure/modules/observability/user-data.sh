#!/bin/bash
set -euxo pipefail

REGION="${region}"
NAMESPACE="${service_discovery_namespace}"
EXPORTER_PORT="${adot_exporter_port}"
GRAFANA_ADMIN_PASSWORD="${grafana_admin_password}"

# Install Docker and docker compose plugin (Amazon Linux 2023)
sudo dnf update -y
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user || true

# Install docker compose v2 if plugin missing
if ! docker compose version >/dev/null 2>&1; then
  sudo dnf install -y docker-compose-plugin || true
fi

# Create directories
sudo mkdir -p /opt/observability/prometheus
sudo mkdir -p /opt/observability/grafana/provisioning/datasources
sudo mkdir -p /opt/observability/grafana/provisioning/dashboards

# Ensure Grafana container (UID 472) can write/read mounted volumes
sudo chown -R 472:472 /opt/observability/grafana || true

# Prometheus config
sudo tee /opt/observability/prometheus/prometheus.yml >/dev/null <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'discovery-server'
    static_configs:
      - targets: ['discovery-server.$${NAMESPACE}:$${EXPORTER_PORT}']
  - job_name: 'config-server'
    static_configs:
      - targets: ['config-server.$${NAMESPACE}:$${EXPORTER_PORT}']
  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway.$${NAMESPACE}:$${EXPORTER_PORT}']
  - job_name: 'user-service'
    static_configs:
      - targets: ['user-service.$${NAMESPACE}:$${EXPORTER_PORT}']
  - job_name: 'task-service'
    static_configs:
      - targets: ['task-service.$${NAMESPACE}:$${EXPORTER_PORT}']
EOF

# Grafana datasource provisioning (Prometheus)
sudo tee /opt/observability/grafana/provisioning/datasources/datasource.yml >/dev/null <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    isDefault: true
    url: http://localhost:9090
    editable: true
EOF

# Run Prometheus
sudo docker rm -f prometheus || true
sudo docker run -d --name prometheus \
  -p 9090:9090 \
  -v /opt/observability/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  --restart unless-stopped \
  prom/prometheus:latest

# Run Grafana
sudo docker rm -f grafana || true
sudo docker run -d --name grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD="$${GRAFANA_ADMIN_PASSWORD}" \
  -v /opt/observability/grafana:/var/lib/grafana \
  -v /opt/observability/grafana/provisioning:/etc/grafana/provisioning \
  --restart unless-stopped \
  grafana/grafana:latest

# Print URLs
echo "Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090" | sudo tee /etc/motd >/dev/null
echo "Grafana:    http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000 (admin / $${GRAFANA_ADMIN_PASSWORD})" | sudo tee -a /etc/motd >/dev/null
