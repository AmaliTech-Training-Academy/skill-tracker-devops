#!/bin/bash

# Sequential service deployment script
set -e

echo "=== Deploying Discovery Server ==="
terraform apply -target=module.app_services.aws_ecs_service.discovery_server -auto-approve

echo "=== Waiting for Discovery Server to be healthy ==="
aws ecs wait services-stable --cluster sdt-dev-cluster --services sdt-dev-discovery-server

echo "=== Deploying Config Server ==="
terraform apply -target=module.app_services.aws_ecs_service.config_server -auto-approve

echo "=== Waiting for Config Server to be healthy ==="
aws ecs wait services-stable --cluster sdt-dev-cluster --services sdt-dev-config-server

echo "=== Deploying API Gateway ==="
terraform apply -target=module.app_services.aws_ecs_service.api_gateway -auto-approve

echo "=== Waiting for API Gateway to be healthy ==="
aws ecs wait services-stable --cluster sdt-dev-cluster --services sdt-dev-api-gateway

echo "=== All services deployed successfully ==="