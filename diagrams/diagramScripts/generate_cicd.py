#!/usr/bin/env python3
"""
Generate CI/CD Pipeline Diagram
Requires: pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Github
from diagrams.onprem.ci import GithubActions
from diagrams.programming.language import Java
from diagrams.aws.devtools import Codebuild
from diagrams.aws.compute import ECR, ECS
from diagrams.aws.management import Cloudwatch
from diagrams.onprem.monitoring import Prometheus  # Using Prometheus icon for SonarQube
from diagrams.saas.chat import Slack
from diagrams.onprem.client import User

graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "0.5",
}

with Diagram(
    "Skill Tracker - CI/CD Pipeline",
    filename="cicd_pipeline",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):
    developer = User("Developer")

    with Cluster("Source Control"):
        github = Github("GitHub\nBackend Repo")

    with Cluster("CI/CD - GitHub Actions"):
        with Cluster("Build Stage"):
            detect = GithubActions("Detect\nChanged Services")
            build_deps = Java("Build Shared\nDependencies")
            build_services = Java("Build\nServices")
            tests = GithubActions("Run\nUnit Tests")

        with Cluster("Quality Stage"):
            sonarqube = Prometheus("SonarQube\nAnalysis")
            quality_gate = GithubActions("Quality\nGate")

        with Cluster("Package Stage"):
            docker_build = Codebuild("Build\nDocker Images")
            ecr_push = ECR("Push to\nECR")

    with Cluster("Deployment"):
        with Cluster("DevOps Repo"):
            dispatch = GithubActions("Repository\nDispatch")
            update_task = GithubActions("Update ECS\nTask Definitions")

        with Cluster("AWS ECS"):
            ecs_deploy = ECS("Deploy to\nECS Fargate")
            health_check = Cloudwatch("Health\nCheck")

    with Cluster("Notifications"):
        slack = Slack("Slack\nNotifications")

    # Flow
    developer >> Edge(label="git push") >> github
    github >> Edge(label="PR merge") >> detect
    detect >> build_deps
    build_deps >> build_services
    build_services >> tests
    tests >> sonarqube
    sonarqube >> quality_gate

    quality_gate >> Edge(label="✅ Pass") >> docker_build
    quality_gate >> Edge(label="❌ Fail", color="red") >> slack

    docker_build >> ecr_push
    ecr_push >> dispatch
    dispatch >> update_task
    update_task >> ecs_deploy
    ecs_deploy >> health_check

    health_check >> Edge(label="✅ Success", color="green") >> slack
    health_check >> Edge(label="❌ Fail", color="red") >> slack

print("✅ CI/CD pipeline diagram generated: cicd_pipeline.png")
