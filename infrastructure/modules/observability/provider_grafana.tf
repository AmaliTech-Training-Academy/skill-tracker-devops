terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.0"
    }
  }
}

provider "grafana" {
  url  = "http://${aws_instance.monitoring.public_ip}:3000"
  auth = "${var.grafana_admin_password}:${var.grafana_admin_password}"
}
