#!/bin/bash

# Test script for deployment changes
# This script tests the changes made to the deploy.sh script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Mock AWS environment variables
export AWS_REGION="us-west-2"
export AWS_ACCOUNT_ID="587210148146"
export DATABASE_PASSWORD="blogpassword"

# Test the build_and_push_images function
test_build_and_push() {
    print_status "Testing build_and_push_images function..."
    
    # Mock AWS CLI commands
    function aws() {
        if [[ "$1" == "ecr" && "$2" == "describe-repositories" ]]; then
            # Simulate repository not existing on first call, existing on second call
            if [[ "$4" == "blog-backend" && ! -f "/tmp/blog-backend-repo-created" ]]; then
                touch "/tmp/blog-backend-repo-created"
                return 1
            elif [[ "$4" == "blog-frontend" && ! -f "/tmp/blog-frontend-repo-created" ]]; then
                touch "/tmp/blog-frontend-repo-created"
                return 1
            fi
            return 0
        elif [[ "$1" == "ecr" && "$2" == "create-repository" ]]; then
            # Simulate repository creation
            if [[ "$4" == "blog-backend" ]]; then
                echo "Repository blog-backend created"
            elif [[ "$4" == "blog-frontend" ]]; then
                echo "Repository blog-frontend created"
            fi
            return 0
        elif [[ "$1" == "ecr" && "$2" == "get-login-password" ]]; then
            # Simulate ECR login token
            echo "mock-ecr-token"
            return 0
        fi
        return 0
    }
    
    # Mock Docker commands
    function docker() {
        if [[ "$1" == "login" ]]; then
            echo "Login Succeeded"
            return 0
        elif [[ "$1" == "build" ]]; then
            echo "Building image..."
            return 0
        elif [[ "$1" == "tag" ]]; then
            echo "Tagging $2 as $4"
            return 0
        elif [[ "$1" == "push" ]]; then
            echo "Pushing $2"
            return 0
        fi
        return 0
    }
    
    # Mock cd command
    function cd() {
        echo "Changing directory to $1"
        return 0
    }
    
    # Source the deploy.sh script to access its functions
    source ./deploy.sh
    
    # Call the build_and_push_images function
    build_and_push_images
    
    print_success "Test completed successfully!"
}

# Test the deploy_infrastructure function
test_deploy_infrastructure() {
    print_status "Testing deploy_infrastructure function..."
    
    # Mock AWS CLI commands
    function aws() {
        if [[ "$1" == "cloudformation" && "$2" == "describe-stacks" ]]; then
            # Simulate stack not existing
            return 1
        elif [[ "$1" == "cloudformation" && "$2" == "create-stack" ]]; then
            # Check if the correct parameters are passed
            if [[ "$*" == *"BackendRepositoryUri"* && "$*" == *"FrontendRepositoryUri"* ]]; then
                echo "Stack creation initiated with correct parameters"
                return 0
            else
                print_error "Stack creation missing required parameters"
                return 1
            fi
        elif [[ "$1" == "cloudformation" && "$2" == "wait" ]]; then
            # Simulate waiting for stack creation
            echo "Waiting for stack creation..."
            return 0
        fi
        return 0
    }
    
    # Source the deploy.sh script to access its functions
    source ./deploy.sh
    
    # Call the deploy_infrastructure function
    deploy_infrastructure
    
    print_success "Test completed successfully!"
}

# Run tests
print_status "Starting tests..."
test_build_and_push
test_deploy_infrastructure
print_success "All tests passed!"