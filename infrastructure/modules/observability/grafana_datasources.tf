# Prometheus datasource (already provisioned via user-data)
# Using data source to reference existing datasource instead of creating new one
data "grafana_data_source" "prometheus" {
  name = "Prometheus"

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
