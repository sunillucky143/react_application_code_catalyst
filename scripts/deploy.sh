#!/bin/bash

# Blog Application Deployment Script
# This script deploys the blog application to AWS using CloudFormation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="blog-app-stack"
ENVIRONMENT=${ENVIRONMENT:-"production"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
ECR_REPOSITORY_URI=${ECR_REPOSITORY_URI:-""}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-""}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check if required environment variables are set
    if [ -z "$ECR_REPOSITORY_URI" ]; then
        print_error "ECR_REPOSITORY_URI environment variable is not set."
        exit 1
    fi
    
    if [ -z "$DATABASE_PASSWORD" ]; then
        print_error "DATABASE_PASSWORD environment variable is not set."
        exit 1
    fi
    
    print_status "Prerequisites check passed."
}

# Function to build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI
    
    # Build and push backend image
    print_status "Building backend image..."
    cd backend
    docker build -t $ECR_REPOSITORY_URI/backend:latest .
    docker push $ECR_REPOSITORY_URI/backend:latest
    cd ..
    
    # Build and push frontend image
    print_status "Building frontend image..."
    cd frontend
    docker build -t $ECR_REPOSITORY_URI/frontend:latest .
    docker push $ECR_REPOSITORY_URI/frontend:latest
    cd ..
    
    print_status "Docker images built and pushed successfully."
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure using CloudFormation..."
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION &> /dev/null; then
        print_status "Stack exists. Updating..."
        aws cloudformation update-stack \
            --stack-name $STACK_NAME \
            --template-body file://infrastructure/cloudformation/main.yaml \
            --parameters \
                ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                ParameterKey=DatabasePassword,ParameterValue=$DATABASE_PASSWORD \
                ParameterKey=ECRRepositoryUri,ParameterValue=$ECR_REPOSITORY_URI \
            --capabilities CAPABILITY_IAM \
            --region $AWS_REGION
        
        # Wait for stack update to complete
        aws cloudformation wait stack-update-complete --stack-name $STACK_NAME --region $AWS_REGION
    else
        print_status "Stack does not exist. Creating..."
        aws cloudformation create-stack \
            --stack-name $STACK_NAME \
            --template-body file://infrastructure/cloudformation/main.yaml \
            --parameters \
                ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                ParameterKey=DatabasePassword,ParameterValue=$DATABASE_PASSWORD \
                ParameterKey=ECRRepositoryUri,ParameterValue=$ECR_REPOSITORY_URI \
            --capabilities CAPABILITY_IAM \
            --region $AWS_REGION
        
        # Wait for stack creation to complete
        aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $AWS_REGION
    fi
    
    print_status "Infrastructure deployment completed."
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application..."
    
    # Get cluster and service names from CloudFormation outputs
    CLUSTER_NAME=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ECSClusterName`].OutputValue' \
        --output text)
    
    BACKEND_SERVICE=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`BackendServiceName`].OutputValue' \
        --output text)
    
    FRONTEND_SERVICE=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`FrontendServiceName`].OutputValue' \
        --output text)
    
    # Update services to force new deployment
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $BACKEND_SERVICE \
        --force-new-deployment \
        --region $AWS_REGION
    
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $FRONTEND_SERVICE \
        --force-new-deployment \
        --region $AWS_REGION
    
    print_status "Application deployment completed."
}

# Function to get deployment information
get_deployment_info() {
    print_status "Getting deployment information..."
    
    # Get ALB DNS name
    ALB_DNS=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ALBDNSName`].OutputValue' \
        --output text)
    
    echo ""
    echo "=========================================="
    echo "DEPLOYMENT COMPLETED SUCCESSFULLY"
    echo "=========================================="
    echo "Application URL: http://$ALB_DNS"
    echo "API Documentation: http://$ALB_DNS/docs"
    echo "Environment: $ENVIRONMENT"
    echo "Region: $AWS_REGION"
    echo "=========================================="
    echo ""
}

# Main deployment function
main() {
    print_status "Starting deployment process..."
    
    check_prerequisites
    build_and_push_images
    deploy_infrastructure
    deploy_application
    get_deployment_info
    
    print_status "Deployment completed successfully!"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "build")
        check_prerequisites
        build_and_push_images
        ;;
    "infrastructure")
        check_prerequisites
        deploy_infrastructure
        ;;
    "application")
        check_prerequisites
        deploy_application
        ;;
    "info")
        get_deployment_info
        ;;
    *)
        echo "Usage: $0 {deploy|build|infrastructure|application|info}"
        echo ""
        echo "Commands:"
        echo "  deploy         - Full deployment (default)"
        echo "  build          - Build and push Docker images only"
        echo "  infrastructure - Deploy infrastructure only"
        echo "  application    - Deploy application only"
        echo "  info           - Show deployment information"
        exit 1
        ;;
esac 