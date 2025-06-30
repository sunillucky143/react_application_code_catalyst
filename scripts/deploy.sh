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
ECR_REPOSITORY_PREFIX=${ECR_REPOSITORY_PREFIX:-"blog"}
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
    if [ -z "$DATABASE_PASSWORD" ]; then
        print_error "DATABASE_PASSWORD environment variable is not set."
        exit 1
    fi
    
    # Get AWS account ID if not provided
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        print_status "AWS_ACCOUNT_ID not set. Attempting to retrieve from AWS CLI..."
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        if [ -z "$AWS_ACCOUNT_ID" ]; then
            print_error "Could not retrieve AWS account ID. Please set AWS_ACCOUNT_ID environment variable."
            exit 1
        fi
        print_status "AWS account ID: $AWS_ACCOUNT_ID"
    fi
    
    print_status "Prerequisites check passed."
}

# Function to build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Create ECR repositories if they don't exist
    print_status "Creating ECR repositories if they don't exist..."
    aws ecr describe-repositories --repository-names blog-backend --region $AWS_REGION || \
    aws ecr create-repository --repository-name blog-backend --region $AWS_REGION
    
    aws ecr describe-repositories --repository-names blog-frontend --region $AWS_REGION || \
    aws ecr create-repository --repository-name blog-frontend --region $AWS_REGION
    
    # Get ECR login token
    print_status "Logging in to ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Build backend image
    print_status "Building backend image..."
    cd backend
    docker build -t backend:latest .
    cd ..
    
    # Build frontend image
    print_status "Building frontend image..."
    cd frontend
    docker build -t frontend:latest .
    cd ..
    
    # Tag and push backend image
    print_status "Tagging and pushing backend image..."
    docker tag backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/blog-backend:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/blog-backend:latest
    
    # Tag and push frontend image
    print_status "Tagging and pushing frontend image..."
    docker tag frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/blog-frontend:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/blog-frontend:latest
    
    print_status "Docker images built and pushed successfully."
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure using CloudFormation..."
    
    # Set ECR repository URIs for backend and frontend
    BACKEND_REPOSITORY_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/blog-backend"
    FRONTEND_REPOSITORY_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/blog-frontend"
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION &> /dev/null; then
        print_status "Stack exists. Updating..."
        CLOUDFORMATION_ERROR=$(aws cloudformation update-stack \
            --stack-name $STACK_NAME \
            --template-body file://infrastructure/cloudformation/main.yaml \
            --parameters \
                ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                ParameterKey=DatabasePassword,ParameterValue=$DATABASE_PASSWORD \
                ParameterKey=BackendRepositoryUri,ParameterValue=$BACKEND_REPOSITORY_URI \
                ParameterKey=FrontendRepositoryUri,ParameterValue=$FRONTEND_REPOSITORY_URI \
            --capabilities CAPABILITY_IAM \
            --region $AWS_REGION 2>&1 || echo $?)
        
        # Check if no updates are to be performed
        if [[ $CLOUDFORMATION_ERROR == *"No updates are to be performed"* ]]; then
            print_status "No updates are to be performed on the stack."
        elif [[ $CLOUDFORMATION_ERROR == *"error"* ]]; then
            print_error "Failed to update CloudFormation stack: $CLOUDFORMATION_ERROR"
            exit 1
        else
            # Wait for stack update to complete
            print_status "Waiting for stack update to complete..."
            aws cloudformation wait stack-update-complete --stack-name $STACK_NAME --region $AWS_REGION
        fi
    else
        print_status "Stack does not exist. Creating..."
        aws cloudformation create-stack \
            --stack-name $STACK_NAME \
            --template-body file://infrastructure/cloudformation/main.yaml \
            --parameters \
                ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
                ParameterKey=DatabasePassword,ParameterValue=$DATABASE_PASSWORD \
                ParameterKey=BackendRepositoryUri,ParameterValue=$BACKEND_REPOSITORY_URI \
                ParameterKey=FrontendRepositoryUri,ParameterValue=$FRONTEND_REPOSITORY_URI \
            --capabilities CAPABILITY_IAM \
            --region $AWS_REGION
        
        # Wait for stack creation to complete
        print_status "Waiting for stack creation to complete..."
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

# Function to run health checks
run_health_checks() {
    print_status "Running health checks..."
    
    # Get ALB DNS name
    ALB_DNS=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ALBDNSName`].OutputValue' \
        --output text)
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready (2 minutes)..."
    sleep 120
    
    # Check frontend health
    print_status "Checking frontend health..."
    if curl -s -f "http://$ALB_DNS/health" > /dev/null; then
        print_status "Frontend health check passed."
    else
        print_warning "Frontend health check failed. The application might still be starting up."
    fi
    
    # Check backend health
    print_status "Checking backend health..."
    if curl -s -f "http://$ALB_DNS/api/health" > /dev/null; then
        print_status "Backend health check passed."
    else
        print_warning "Backend health check failed. The API might still be starting up."
    fi
}

# Main deployment function
main() {
    print_status "Starting deployment process..."
    
    check_prerequisites
    build_and_push_images
    deploy_infrastructure
    deploy_application
    run_health_checks
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
    "health")
        check_prerequisites
        run_health_checks
        ;;
    "info")
        check_prerequisites
        get_deployment_info
        ;;
    *)
        echo "Usage: $0 {deploy|build|infrastructure|application|health|info}"
        echo ""
        echo "Commands:"
        echo "  deploy         - Full deployment (default)"
        echo "  build          - Build and push Docker images only"
        echo "  infrastructure - Deploy infrastructure only"
        echo "  application    - Deploy application only"
        echo "  health         - Run health checks"
        echo "  info           - Show deployment information"
        exit 1
        ;;
esac 