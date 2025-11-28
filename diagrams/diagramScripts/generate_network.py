#!/usr/bin/env python3
"""
Generate Network Architecture Diagram
Requires: pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import VPC, InternetGateway, NATGateway, ALB, Route53
from diagrams.aws.compute import ECS
from diagrams.aws.database import RDS
from diagrams.onprem.client import Users

graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "0.5",
}

with Diagram(
    "Skill Tracker - Network Architecture",
    filename="network_architecture",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
):
    users = Users("Internet Users")
    igw = InternetGateway("Internet Gateway")

    with Cluster("VPC 10.x.0.0/16"):
        with Cluster("Availability Zone 1a"):
            with Cluster("Public Subnet 1\n10.x.1.0/24"):
                alb1 = ALB("ALB")
                nat1 = NATGateway("NAT Gateway 1")

            with Cluster("Private Subnet 1\n10.x.10.0/24"):
                ecs1 = ECS("ECS Tasks\n(Services)")
                rds1 = RDS("RDS Primary")

        with Cluster("Availability Zone 1b"):
            with Cluster("Public Subnet 2\n10.x.2.0/24"):
                alb2 = ALB("ALB")
                nat2 = NATGateway("NAT Gateway 2")

            with Cluster("Private Subnet 2\n10.x.11.0/24"):
                ecs2 = ECS("ECS Tasks\n(Services)")
                rds2 = RDS("RDS Standby")

    # Internet to IGW
    users >> Edge(label="HTTPS") >> igw

    # IGW to ALBs
    igw >> Edge(label="Public") >> alb1
    igw >> Edge(label="Public") >> alb2

    # ALBs to ECS
    alb1 >> Edge(label="Private") >> ecs1
    alb2 >> Edge(label="Private") >> ecs2

    # ECS to NAT (for outbound)
    ecs1 >> Edge(label="Outbound", style="dashed") >> nat1
    ecs2 >> Edge(label="Outbound", style="dashed") >> nat2

    # NAT to IGW
    nat1 >> Edge(style="dashed") >> igw
    nat2 >> Edge(style="dashed") >> igw

    # ECS to RDS
    ecs1 >> Edge(label="5432") >> rds1
    ecs2 >> Edge(label="5432") >> rds1

    # RDS replication
    rds1 >> Edge(label="Replication", style="dotted") >> rds2

print("✅ Network diagram generated: network_architecture.png")
