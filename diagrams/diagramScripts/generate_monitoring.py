#!/usr/bin/env python3
"""
Generate Monitoring & Observability Diagram
Requires: pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS, Lambda
from diagrams.aws.management import Cloudwatch
from diagrams.aws.integration import SNS
from diagrams.aws.storage import S3
from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.tracing import Jaeger
from diagrams.saas.chat import Slack

# Note: Using Jaeger icon for X-Ray as diagrams library doesn't have dedicated X-Ray icon
# Both are distributed tracing systems with similar functionality

graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "0.5",
}

with Diagram(
    "Skill Tracker - Monitoring & Observability",
    filename="monitoring_stack",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
):
    with Cluster("Application Layer"):
        services = [
            ECS("User Service"),
            ECS("Task Service"),
            ECS("Analytics Service"),
            ECS("Feedback Service"),
            ECS("Notification Service"),
        ]

    with Cluster("Logs Pipeline"):
        cw_logs = Cloudwatch("CloudWatch\nLogs")
        log_exporter = Lambda("Log\nExporter")
        s3_logs = S3("S3 Logs\nArchive")

    with Cluster("Metrics Pipeline"):
        cw_metrics = Cloudwatch("CloudWatch\nMetrics")
        grafana = Grafana("Grafana\nDashboards")

    with Cluster("Cost Monitoring"):
        cost_lambda = Lambda("Cost\nExporter")
        cost_metrics = Cloudwatch("Cost\nMetrics")

    with Cluster("Alerting"):
        alarms = Cloudwatch("CloudWatch\nAlarms")
        sns = SNS("SNS\nTopic")
        slack = Slack("Slack\nAlerts")

    with Cluster("Tracing (Staging/Prod)"):
        xray = Jaeger("AWS X-Ray\n[Distributed Tracing]")

    # Logs flow
    services >> Edge(label="Logs") >> cw_logs
    cw_logs >> Edge(label="Export") >> log_exporter
    log_exporter >> Edge(label="Archive") >> s3_logs

    # Metrics flow
    services >> Edge(label="Metrics") >> cw_metrics
    cw_metrics >> Edge(label="Query") >> grafana

    # Cost monitoring
    cost_lambda >> Edge(label="Publish") >> cost_metrics
    cost_metrics >> grafana

    # Alerting flow
    cw_metrics >> Edge(label="Threshold") >> alarms
    alarms >> sns
    sns >> slack

    # Tracing
    services >> Edge(label="Traces", style="dashed") >> xray

print("✅ Monitoring diagram generated: monitoring_stack.png")
