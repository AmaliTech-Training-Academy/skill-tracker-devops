#!/usr/bin/env python3
"""
Generate Skill Tracker Architecture Diagram
Requires: pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS
from diagrams.aws.database import RDS
from diagrams.aws.network import ALB, CloudFront
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch
from diagrams.onprem.client import Users
from diagrams.onprem.database import MongoDB
from diagrams.onprem.queue import RabbitMQ
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.monitoring import Grafana
from diagrams.programming.framework import Spring

# Note: Using S3 icon for Amplify as diagrams library doesn't have dedicated Amplify icon
# Amplify uses S3 + CloudFront under the hood anyway

# Configure diagram
graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "0.5",
}

with Diagram(
    "Skill Tracker - Complete Architecture",
    filename="architecture_overview",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
):
    users = Users("Users")

    with Cluster("AWS Cloud"):
        # Frontend Layer
        with Cluster("Frontend Layer"):
            cdn = CloudFront("CloudFront CDN")
            amplify = S3("AWS Amplify\n(Angular App)\n[S3 + CloudFront]")

        # API Layer
        with Cluster("API Layer"):
            alb = ALB("Application\nLoad Balancer")

        # ECS Cluster
        with Cluster("ECS Fargate Cluster"):
            with Cluster("Core Services"):
                config_server = Spring("Config Server\n:8081")
                discovery_server = Spring("Discovery Server\n:8082")
                api_gateway = Spring("API Gateway\n:8080")

            with Cluster("Business Services"):
                user_service = ECS("User Service\n:8083")
                task_service = ECS("Task Service\n:8084")
                analytics_service = ECS("Analytics Service\n:8087")
                feedback_service = ECS("Feedback Service\n:8088")
                notification_service = ECS("Notification Service\n:8089")

        # Data Services
        with Cluster("Data Services (ECS)"):
            mongodb = MongoDB("MongoDB\n:27017")
            rabbitmq = RabbitMQ("RabbitMQ\n:5672")
            redis = Redis("Redis\n:6379")

        # Database Layer
        with Cluster("Database Layer"):
            rds = RDS("PostgreSQL\nRDS Multi-AZ")

        # Storage
        with Cluster("Storage"):
            s3_uploads = S3("User Uploads")
            s3_logs = S3("Application Logs")

        # Monitoring
        with Cluster("Monitoring & Observability"):
            cloudwatch = Cloudwatch("CloudWatch")
            grafana = Grafana("Grafana")

    # User connections
    users >> Edge(label="HTTPS") >> cdn
    cdn >> Edge(label="Static Assets") >> amplify
    cdn >> Edge(label="API Calls") >> alb

    # ALB to API Gateway
    alb >> api_gateway

    # API Gateway to Core Services
    api_gateway >> config_server
    api_gateway >> discovery_server

    # API Gateway to Business Services
    api_gateway >> user_service
    api_gateway >> task_service
    api_gateway >> analytics_service
    api_gateway >> feedback_service
    api_gateway >> notification_service

    # Database connections
    user_service >> rds
    task_service >> rds
    feedback_service >> rds

    # MongoDB connections
    task_service >> mongodb
    analytics_service >> mongodb
    notification_service >> mongodb

    # RabbitMQ connections
    notification_service >> rabbitmq
    task_service >> rabbitmq
    analytics_service >> rabbitmq

    # Redis connections
    user_service >> redis
    api_gateway >> redis

    # S3 connections
    user_service >> s3_uploads
    task_service >> s3_uploads
    [user_service, task_service, analytics_service] >> s3_logs

    # Monitoring connections
    [
        user_service,
        task_service,
        analytics_service,
        feedback_service,
        notification_service,
    ] >> cloudwatch
    cloudwatch >> grafana

print("✅ Architecture diagram generated: architecture_overview.png")
