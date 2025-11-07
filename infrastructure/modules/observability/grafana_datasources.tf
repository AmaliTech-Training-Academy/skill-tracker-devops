# Prometheus datasource (already provisioned via user-data, but managed here for completeness)
resource "grafana_data_source" "prometheus" {
  type       = "prometheus"
  name       = "Prometheus"
  url        = "http://prometheus:9090"
  is_default = true

  depends_on = [aws_instance.monitoring]
}

# CloudWatch datasource for AWS infrastructure metrics
resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "CloudWatch"

  json_data_encoded = jsonencode({
    authType      = "default"
    defaultRegion = var.aws_region
  })

  depends_on = [aws_instance.monitoring]
}
