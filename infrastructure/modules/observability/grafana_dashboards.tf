# Prometheus-based Service Overview Dashboard
resource "grafana_dashboard" "service_overview" {
  config_json = file("${path.module}/dashboards/sdt-service-overview.json")

  depends_on = [data.grafana_data_source.prometheus]
}

# CloudWatch-based Infrastructure Dashboard
resource "grafana_dashboard" "infrastructure" {
  config_json = replace(
    file("${path.module}/dashboards/sdt-infrastructure.json"),
    "$${CLOUDWATCH_UID}",
    grafana_data_source.cloudwatch.uid
  )

  depends_on = [grafana_data_source.cloudwatch]
}

# OLD VERSION - keeping for reference, delete after testing
resource "grafana_dashboard" "infrastructure_old" {
  count = 0
  config_json = jsonencode({
    title         = "SDT - Infrastructure Overview"
    uid           = "sdt-infrastructure"
    tags          = ["cloudwatch", "sdt", "infrastructure"]
    timezone      = "browser"
    schemaVersion = 38
    version       = 1
    refresh       = "1m"

    panels = [
      # ECS Cluster CPU Utilization
      {
        title   = "ECS Cluster CPU Utilization"
        type    = "timeseries"
        gridPos = { x = 0, y = 0, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/ECS"
            metricName = "CPUUtilization"
            dimensions = {
              ClusterName = "${var.project_name}-${var.environment}-cluster"
            }
            statistic = "Average"
            period    = 300
            refId     = "A"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "percent"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 70 },
                { color = "red", value = 85 }
              ]
            }
          }
        }
      },

      # ECS Services Memory Utilization
      {
        title   = "ECS Services Memory Utilization"
        type    = "timeseries"
        gridPos = { x = 12, y = 0, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/ECS"
            metricName = "MemoryUtilization"
            dimensions = {
              ServiceName = "*"
              ClusterName = "${var.project_name}-${var.environment}-cluster"
            }
            statistic = "Average"
            period    = 300
            refId     = "B"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "percent"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 75 },
                { color = "red", value = 90 }
              ]
            }
          }
        }
      },

      # RDS CPU Utilization
      {
        title   = "RDS CPU Utilization"
        type    = "timeseries"
        gridPos = { x = 0, y = 8, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/RDS"
            metricName = "CPUUtilization"
            dimensions = {
              DBInstanceIdentifier = "${var.project_name}-${var.environment}-postgres"
            }
            statistic = "Average"
            period    = 300
            refId     = "C"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "percent"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 70 },
                { color = "red", value = 85 }
              ]
            }
          }
        }
      },

      # RDS Database Connections
      {
        title   = "RDS Database Connections"
        type    = "timeseries"
        gridPos = { x = 12, y = 8, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/RDS"
            metricName = "DatabaseConnections"
            dimensions = {
              DBInstanceIdentifier = "${var.project_name}-${var.environment}-postgres"
            }
            statistic = "Average"
            period    = 300
            refId     = "D"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "short"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 80 },
                { color = "red", value = 95 }
              ]
            }
          }
        }
      },

      # RDS Free Storage Space
      {
        title   = "RDS Free Storage Space"
        type    = "timeseries"
        gridPos = { x = 0, y = 16, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/RDS"
            metricName = "FreeStorageSpace"
            dimensions = {
              DBInstanceIdentifier = "${var.project_name}-${var.environment}-postgres"
            }
            statistic = "Average"
            period    = 300
            refId     = "E"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "bytes"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red", value = null },
                { color = "yellow", value = 5000000000 },
                { color = "green", value = 10000000000 }
              ]
            }
          }
        }
      },

      # ALB Request Count
      {
        title   = "ALB Request Count"
        type    = "timeseries"
        gridPos = { x = 12, y = 16, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/ApplicationELB"
            metricName = "RequestCount"
            dimensions = {
              LoadBalancer = "app/${var.project_name}-${var.environment}-alb/2874514f99ee3911"
            }
            statistic = "Sum"
            period    = 300
            refId     = "F"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "short"
          }
        }
      },

      # ALB Target Response Time
      {
        title   = "ALB Target Response Time"
        type    = "timeseries"
        gridPos = { x = 0, y = 24, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/ApplicationELB"
            metricName = "TargetResponseTime"
            dimensions = {
              LoadBalancer = "app/${var.project_name}-${var.environment}-alb/2874514f99ee3911"
            }
            statistic = "Average"
            period    = 300
            refId     = "G"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "s"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 1 },
                { color = "red", value = 3 }
              ]
            }
          }
        }
      },

      # ALB 5xx Errors
      {
        title   = "ALB 5xx Errors"
        type    = "timeseries"
        gridPos = { x = 12, y = 24, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/ApplicationELB"
            metricName = "HTTPCode_Target_5XX_Count"
            dimensions = {
              LoadBalancer = "app/${var.project_name}-${var.environment}-alb/2874514f99ee3911"
            }
            statistic = "Sum"
            period    = 300
            refId     = "H"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "short"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 5 },
                { color = "red", value = 20 }
              ]
            }
          }
        }
      },

      # NAT Gateway Bytes Out
      {
        title   = "NAT Gateway Bytes Out"
        type    = "timeseries"
        gridPos = { x = 0, y = 32, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/NATGateway"
            metricName = "BytesOutToDestination"
            statistic  = "Sum"
            period     = 300
            refId      = "I"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "bytes"
          }
        }
      },

      # VPC Flow Logs (if enabled)
      {
        title   = "VPC Network Packets In"
        type    = "timeseries"
        gridPos = { x = 12, y = 32, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/EC2"
            metricName = "NetworkPacketsIn"
            statistic  = "Sum"
            period     = 300
            refId      = "J"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "short"
          }
        }
      }
    ]
  })

  depends_on = [grafana_data_source.cloudwatch]
}

# Cost Monitoring Dashboard
resource "grafana_dashboard" "cost_monitoring" {
  config_json = replace(
    file("${path.module}/dashboards/sdt-cost-monitoring.json"),
    "$${CLOUDWATCH_UID}",
    grafana_data_source.cloudwatch.uid
  )

  depends_on = [grafana_data_source.cloudwatch]
}

# OLD VERSION - keeping for reference, delete after testing
resource "grafana_dashboard" "cost_monitoring_old" {
  count = 0
  config_json = jsonencode({
    title         = "SDT - Cost Monitoring"
    uid           = "sdt-cost-monitoring"
    tags          = ["cloudwatch", "sdt", "cost", "billing"]
    timezone      = "browser"
    schemaVersion = 38
    version       = 1
    refresh       = "1h"

    panels = [
      # Estimated Charges
      {
        title   = "Estimated AWS Charges (Last 24h)"
        type    = "stat"
        gridPos = { x = 0, y = 0, w = 8, h = 6 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = "us-east-1" # Billing metrics only in us-east-1
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency = "USD"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "A"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "currencyUSD"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 100 },
                { color = "red", value = 200 }
              ]
            }
          }
        }
      },

      # ECS Service Charges
      {
        title   = "ECS Service Charges"
        type    = "stat"
        gridPos = { x = 8, y = 0, w = 8, h = 6 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency    = "USD"
              ServiceName = "Amazon Elastic Container Service"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "B"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "currencyUSD"
          }
        }
      },

      # RDS Charges
      {
        title   = "RDS Charges"
        type    = "stat"
        gridPos = { x = 16, y = 0, w = 8, h = 6 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency    = "USD"
              ServiceName = "Amazon Relational Database Service"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "C"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "currencyUSD"
          }
        }
      },

      # Cost Trend Over Time
      {
        title   = "Cost Trend (Last 7 Days)"
        type    = "timeseries"
        gridPos = { x = 0, y = 6, w = 24, h = 10 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency = "USD"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "D"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "currencyUSD"
          }
        }
      },

      # Service Breakdown
      {
        title   = "Cost by Service"
        type    = "timeseries"
        gridPos = { x = 0, y = 16, w = 24, h = 10 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency    = "USD"
              ServiceName = "Amazon Elastic Container Service"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "E"
            alias     = "ECS"
          },
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency    = "USD"
              ServiceName = "Amazon Relational Database Service"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "F"
            alias     = "RDS"
          },
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency    = "USD"
              ServiceName = "Amazon Elastic Compute Cloud"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "G"
            alias     = "EC2"
          },
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency    = "USD"
              ServiceName = "Amazon Simple Storage Service"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "H"
            alias     = "S3"
          },
          {
            region     = "us-east-1"
            namespace  = "AWS/Billing"
            metricName = "EstimatedCharges"
            dimensions = {
              Currency    = "USD"
              ServiceName = "AWS Amplify"
            }
            statistic = "Maximum"
            period    = 86400
            refId     = "I"
            alias     = "Amplify"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "currencyUSD"
          }
        }
      },

      # Data Transfer Costs
      {
        title   = "Data Transfer Out (GB)"
        type    = "timeseries"
        gridPos = { x = 0, y = 26, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/NATGateway"
            metricName = "BytesOutToDestination"
            statistic  = "Sum"
            period     = 3600
            refId      = "J"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "decgbytes"
          }
        }
      },

      # NAT Gateway Cost Indicator
      {
        title   = "NAT Gateway Data Processed (GB)"
        type    = "timeseries"
        gridPos = { x = 12, y = 26, w = 12, h = 8 }
        datasource = {
          type = "cloudwatch"
          uid  = grafana_data_source.cloudwatch.uid
        }
        targets = [
          {
            region     = var.aws_region
            namespace  = "AWS/NATGateway"
            metricName = "BytesInFromDestination"
            statistic  = "Sum"
            period     = 3600
            refId      = "K"
          }
        ]
        fieldConfig = {
          defaults = {
            unit = "decgbytes"
          }
        }
      }
    ]

    annotations = {
      list = [
        {
          name       = "Cost Alerts"
          datasource = "-- Grafana --"
          enable     = true
          iconColor  = "red"
        }
      ]
    }
  })

  depends_on = [grafana_data_source.cloudwatch]
}
