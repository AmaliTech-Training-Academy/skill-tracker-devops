#!/bin/bash

# =============================================================================
# Skills Development Tracker (SDT) - Infrastructure Setup Script
# =============================================================================
# This script helps you set up the SDT infrastructure for the first time.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        return 1
    else
        print_success "$1 is installed"
        return 0
    fi
}

# Main script
print_header "SDT Infrastructure Setup"

# Check prerequisites
print_info "Checking prerequisites..."

if ! check_command "terraform"; then
    print_error "Please install Terraform: https://www.terraform.io/downloads"
    exit 1
fi

if ! check_command "aws"; then
    print_error "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

if ! check_command "make"; then
    print_warning "Make is not installed. You can still use terraform commands directly."
fi

# Check AWS credentials
print_info "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_success "AWS credentials configured (Account: $ACCOUNT_ID)"
else
    print_error "AWS credentials not configured. Please run 'aws configure'"
    exit 1
fi

# Select environment
print_header "Environment Selection"
echo "Select environment to set up:"
echo "1) dev"
echo "2) staging"
echo "3) production"
read -p "Enter choice [1-3]: " env_choice

case $env_choice in
    1) ENV="dev" ;;
    2) ENV="staging" ;;
    3) ENV="production" ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_success "Selected environment: $ENV"

# Create backend resources
print_header "Backend Setup"
print_info "Creating S3 bucket and DynamoDB table for Terraform state..."

# Create S3 bucket
BUCKET_NAME="sdt-terraform-state"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    print_info "Creating S3 bucket: $BUCKET_NAME"
    aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1
    aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
    aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    print_success "S3 bucket created: $BUCKET_NAME"
else
    print_success "S3 bucket already exists: $BUCKET_NAME"
fi

# Create DynamoDB table
TABLE_NAME="sdt-${ENV}-locks"
if aws dynamodb describe-table --table-name $TABLE_NAME --region us-east-1 &> /dev/null; then
    print_success "DynamoDB table already exists: $TABLE_NAME"
else
    print_info "Creating DynamoDB table: $TABLE_NAME"
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region us-east-1 > /dev/null
    print_success "DynamoDB table created: $TABLE_NAME"
fi

# Set up environment configuration
print_header "Environment Configuration"

TFVARS_FILE="envs/$ENV/terraform.tfvars"

if [ -f "$TFVARS_FILE" ]; then
    print_warning "terraform.tfvars already exists for $ENV environment"
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        print_info "Skipping terraform.tfvars creation"
    else
        cp terraform.tfvars.example "$TFVARS_FILE"
        print_success "Created $TFVARS_FILE from example"
        print_warning "Please edit $TFVARS_FILE with your specific values"
    fi
else
    cp terraform.tfvars.example "$TFVARS_FILE"
    print_success "Created $TFVARS_FILE from example"
    print_warning "Please edit $TFVARS_FILE with your specific values"
fi

# Initialize Terraform
print_header "Terraform Initialization"
read -p "Initialize Terraform now? (Y/n): " init_terraform

if [[ ! $init_terraform =~ ^[Nn]$ ]]; then
    print_info "Initializing Terraform for $ENV environment..."
    cd "envs/$ENV" && terraform init
    print_success "Terraform initialized"
    cd ../..
else
    print_info "Skipping Terraform initialization"
fi

# Summary
print_header "Setup Complete!"
echo -e "${GREEN}Next steps:${NC}"
echo ""
echo "1. Edit your environment variables:"
echo "   ${BLUE}vi envs/$ENV/terraform.tfvars${NC}"
echo ""
echo "2. Review the infrastructure plan:"
echo "   ${BLUE}cd envs/$ENV && terraform plan${NC}"
echo "   or"
echo "   ${BLUE}make plan ENV=$ENV${NC}"
echo ""
echo "3. Apply the infrastructure:"
echo "   ${BLUE}cd envs/$ENV && terraform apply${NC}"
echo "   or"
echo "   ${BLUE}make apply ENV=$ENV${NC}"
echo ""
echo "4. View the outputs:"
echo "   ${BLUE}make output ENV=$ENV${NC}"
echo ""
print_info "For more information, see the README.md file"
print_success "Happy deploying! 🚀"
