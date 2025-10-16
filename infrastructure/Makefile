.PHONY: help init plan apply destroy validate fmt clean

# Default environment
ENV ?= dev

help: ## Show this help message
	@echo 'Usage: make [target] ENV=[dev|staging|production]'
	@echo ''
	@echo 'Available targets:'
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform for the specified environment
	@echo "Initializing Terraform for $(ENV) environment..."
	cd envs/$(ENV) && terraform init

plan: ## Run Terraform plan for the specified environment
	@echo "Running Terraform plan for $(ENV) environment..."
	cd envs/$(ENV) && terraform plan

apply: ## Apply Terraform changes for the specified environment
	@echo "Applying Terraform changes for $(ENV) environment..."
	cd envs/$(ENV) && terraform apply

apply-auto: ## Apply Terraform changes without confirmation
	@echo "Auto-applying Terraform changes for $(ENV) environment..."
	cd envs/$(ENV) && terraform apply -auto-approve

destroy: ## Destroy Terraform-managed infrastructure
	@echo "WARNING: This will destroy all resources in $(ENV) environment!"
	@echo "Press Ctrl+C to cancel or Enter to continue..."
	@read confirm
	cd envs/$(ENV) && terraform destroy

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration for $(ENV) environment..."
	cd envs/$(ENV) && terraform validate

fmt: ## Format Terraform files
	@echo "Formatting Terraform files..."
	terraform fmt -recursive .

fmt-check: ## Check if Terraform files are formatted
	@echo "Checking Terraform file formatting..."
	terraform fmt -check -recursive .

clean: ## Clean Terraform cache files
	@echo "Cleaning Terraform cache files..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find . -type f -name "terraform.tfstate*" -delete 2>/dev/null || true

output: ## Show Terraform outputs
	@echo "Showing outputs for $(ENV) environment..."
	cd envs/$(ENV) && terraform output

output-json: ## Show Terraform outputs in JSON format
	@echo "Showing outputs in JSON for $(ENV) environment..."
	cd envs/$(ENV) && terraform output -json

refresh: ## Refresh Terraform state
	@echo "Refreshing Terraform state for $(ENV) environment..."
	cd envs/$(ENV) && terraform refresh

state-list: ## List resources in Terraform state
	@echo "Listing resources for $(ENV) environment..."
	cd envs/$(ENV) && terraform state list

graph: ## Generate Terraform dependency graph
	@echo "Generating dependency graph for $(ENV) environment..."
	cd envs/$(ENV) && terraform graph | dot -Tpng > terraform-graph-$(ENV).png
	@echo "Graph saved to envs/$(ENV)/terraform-graph-$(ENV).png"

# Backend setup commands
setup-backend: ## Create S3 bucket and DynamoDB table for Terraform state
	@echo "Setting up Terraform backend for $(ENV) environment..."
	@BUCKET_SUFFIX=$$(openssl rand -hex 4); \
	BUCKET_NAME="sdt-terraform-state-$$BUCKET_SUFFIX"; \
	echo "Creating S3 bucket: $$BUCKET_NAME"; \
	aws s3api create-bucket \
		--bucket $$BUCKET_NAME \
		--region eu-west-1 \
		--create-bucket-configuration LocationConstraint=eu-west-1 && \
	aws s3api put-bucket-versioning \
		--bucket $$BUCKET_NAME \
		--versioning-configuration Status=Enabled \
		--region eu-west-1 && \
	aws s3api put-bucket-encryption \
		--bucket $$BUCKET_NAME \
		--server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}' \
		--region eu-west-1 && \
	echo "Creating DynamoDB table: sdt-terraform-locks" && \
	aws dynamodb create-table \
		--table-name sdt-terraform-locks \
		--attribute-definitions AttributeName=LockID,AttributeType=S \
		--key-schema AttributeName=LockID,KeyType=HASH \
		--billing-mode PAY_PER_REQUEST \
		--region eu-west-1 && \
	echo "" && \
	echo "Backend setup complete!" && \
	echo "" && \
	echo "Update your envs/$(ENV)/provider.tf with:" && \
	echo "  bucket         = \"$$BUCKET_NAME\"" && \
	echo "  region         = \"eu-west-1\"" && \
	echo "  dynamodb_table = \"sdt-terraform-locks\""

# ECR login
ecr-login: ## Login to Amazon ECR
	@echo "Logging into Amazon ECR..."
	@aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-1.amazonaws.com

# All environments
init-all: ## Initialize all environments
	@make init ENV=dev
	@make init ENV=staging
	@make init ENV=production

plan-all: ## Plan all environments
	@make plan ENV=dev
	@make plan ENV=staging
	@make plan ENV=production

validate-all: ## Validate all environments
	@make validate ENV=dev
	@make validate ENV=staging
	@make validate ENV=production
