#!/usr/bin/env python3
"""
Generate Data Flow Diagram
Requires: pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS
from diagrams.aws.database import RDS
from diagrams.onprem.database import MongoDB
from diagrams.onprem.queue import RabbitMQ
from diagrams.onprem.client import User

graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "0.5",
}

with Diagram(
    "Skill Tracker - Data Flow (Task Submission)",
    filename="data_flow",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):
    user = User("User")

    with Cluster("API Layer"):
        api_gateway = ECS("API Gateway\n:8080")

    with Cluster("Business Logic"):
        task_service = ECS("Task Service\n:8084")

    with Cluster("Data Persistence"):
        postgres = RDS("PostgreSQL\n(Task Metadata)")
        mongo = MongoDB("MongoDB\n(Submissions)")

    with Cluster("Event Processing"):
        rabbitmq = RabbitMQ("RabbitMQ\nMessage Queue")

        with Cluster("Event Consumers"):
            analytics = ECS("Analytics\nService")
            notification = ECS("Notification\nService")
            recommendation = ECS("Recommendation\nService")

    # Request flow
    user >> Edge(label="1. Submit Task") >> api_gateway
    api_gateway >> Edge(label="2. Route") >> task_service

    # Data persistence (parallel)
    task_service >> Edge(label="3a. Save Metadata", color="blue") >> postgres
    task_service >> Edge(label="3b. Save Submission", color="green") >> mongo

    # Event publishing
    task_service >> Edge(label="4. Publish Event") >> rabbitmq

    # Event consumption (parallel)
    rabbitmq >> Edge(label="5a. TaskSubmitted", color="orange") >> analytics
    rabbitmq >> Edge(label="5b. TaskSubmitted", color="purple") >> notification
    rabbitmq >> Edge(label="5c. TaskSubmitted", color="red") >> recommendation

    # Consumers write back
    analytics >> Edge(style="dashed") >> mongo
    notification >> Edge(style="dashed") >> mongo

    # Response
    task_service >> Edge(label="6. Response", style="dotted") >> api_gateway
    api_gateway >> Edge(label="7. Success", style="dotted") >> user

print("✅ Data flow diagram generated: data_flow.png")
