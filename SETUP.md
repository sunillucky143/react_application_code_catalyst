# Blog Application Setup Guide

This guide will help you set up and deploy the full-stack blog application using AWS CodeCatalyst.

## 🏗️ Architecture Overview

The application consists of:
- **Frontend**: React SPA with Tailwind CSS
- **Backend**: FastAPI with PostgreSQL
- **Infrastructure**: AWS ECS Fargate, RDS, ALB, VPC
- **CI/CD**: AWS CodeCatalyst workflows

## 📋 Prerequisites

### Local Development
- Node.js 18+ and npm
- Python 3.9+
- Docker and Docker Compose
- Git

### AWS Deployment
- AWS CLI configured
- AWS CodeCatalyst access
- ECR repository created
- Appropriate AWS permissions

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd react_application_code_catalyst
```

### 2. Local Development Setup

#### Option A: Using Docker Compose (Recommended)
```bash
# Copy environment files
cp backend/env.example backend/.env
cp frontend/env.example frontend/.env

# Start all services
docker-compose up --build
```

#### Option B: Manual Setup
```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Frontend (in another terminal)
cd frontend
npm install
npm start
```

### 3. Access the Application
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest
```

### Frontend Tests
```bash
cd frontend
npm test
```

### Integration Tests
```bash
# Run with docker-compose
docker-compose -f docker-compose.test.yml up --build
```

## 🚀 AWS Deployment

### 1. CodeCatalyst Setup

#### Create CodeCatalyst Space and Project
1. Go to [AWS CodeCatalyst](https://codecatalyst.aws/)
2. Create a new space
3. Create a new project
4. Connect your source repository

#### Set Up Environment Variables
In your CodeCatalyst project, add these environment variables:
- `AWS_REGION`: Your AWS region (e.g., us-east-1)
- `AWS_ACCOUNT_ID`: Your AWS account ID
- `DATABASE_PASSWORD`: Secure database password
- `ECR_REPOSITORY_PREFIX`: Repository prefix (default: "blog")

#### Configure AWS Connection
1. Go to Project Settings > Environments
2. Create a new environment called "production"
3. Add AWS connection with appropriate permissions:
   - ECR: Full access
   - CloudFormation: Full access
   - ECS: Full access
   - IAM: Limited access for role creation

### 2. CodeCatalyst Workflow
The project includes a pre-configured workflow in `.codecatalyst/workflows/main.yaml` that:

1. **Builds** Docker images for frontend and backend
2. **Tests** the application with unit tests and security scans
3. **Deploys** to AWS using CloudFormation and ECS

The workflow runs automatically when:
- Code is pushed to the main branch
- Pull requests are created or updated

### 3. ECR Repository Setup
```bash
# Create ECR repositories
aws ecr create-repository --repository-name blog-backend --region us-east-1
aws ecr create-repository --repository-name blog-frontend --region us-east-1

# Get repository URIs
aws ecr describe-repositories --region us-east-1
```

### 4. Manual Deployment (Alternative)

#### Using the Deployment Script
```bash
# Make script executable
chmod +x scripts/deploy.sh

# Set environment variables
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=your-aws-account-id
export DATABASE_PASSWORD=your-secure-password
export ECR_REPOSITORY_PREFIX=blog

# Deploy
./scripts/deploy.sh
```

#### Using AWS CLI Directly
```bash
# Deploy infrastructure
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/main.yaml \
  --stack-name blog-app-stack \
  --parameter-overrides \
    Environment=production \
    DatabasePassword=your-secure-password \
    ECRRepositoryUri=your-aws-account-id.dkr.ecr.us-east-1.amazonaws.com/blog \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```env
DATABASE_URL=postgresql://bloguser:blogpassword@localhost:5432/blogdb
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ALGORITHM=HS256
JWT_EXPIRATION=3600
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
DEBUG=true
ENVIRONMENT=development
API_PREFIX=/api
```

#### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:8000
REACT_APP_ENVIRONMENT=development
```

### Production Configuration
For production deployment, update the environment variables:
- Set `DEBUG=false`
- Use strong `JWT_SECRET`
- Configure proper `CORS_ORIGINS`
- Use production database URL

## 📊 Monitoring and Logs

### CloudWatch Logs
- Backend logs: `/ecs/production-blog-backend`
- Frontend logs: `/ecs/production-blog-frontend`

### Health Checks
- Backend: `http://your-alb-url/health`
- Frontend: `http://your-alb-url/health`

### Metrics
Monitor these CloudWatch metrics:
- ECS service metrics
- ALB metrics
- RDS metrics

## 🔒 Security

### Best Practices
1. **Secrets Management**: Use AWS Secrets Manager for sensitive data
2. **Network Security**: All services run in private subnets
3. **IAM Roles**: Least privilege access
4. **HTTPS**: Configure SSL/TLS certificates
5. **Database**: Encrypted at rest and in transit

### Security Headers
The application includes security headers:
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Referrer-Policy

## 🐛 Troubleshooting

### Common Issues

#### Database Connection Issues
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check database logs
docker-compose logs db
```

#### Frontend Build Issues
```bash
# Clear npm cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

#### Backend Import Errors
```bash
# Check Python path
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

#### AWS Deployment Issues
```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks --stack-name blog-app-stack

# Check ECS service status
aws ecs describe-services --cluster production-blog-cluster --services production-blog-backend-service
```

### Logs
```bash
# Backend logs
docker-compose logs backend

# Frontend logs
docker-compose logs frontend

# Database logs
docker-compose logs db
```

## 📚 API Documentation

### Interactive API Docs
- Swagger UI: `http://your-alb-url/docs`
- ReDoc: `http://your-alb-url/redoc`

### Key Endpoints
- `GET /api/posts` - List all posts
- `POST /api/posts` - Create new post (authenticated)
- `GET /api/posts/{id}` - Get single post
- `PUT /api/posts/{id}` - Update post (authenticated)
- `DELETE /api/posts/{id}` - Delete post (authenticated)
- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User authentication
- `GET /api/users/me` - Get current user (authenticated)

## 🔄 Development Workflow

### Feature Development
1. Create feature branch from main
2. Implement changes
3. Write tests
4. Create pull request
5. Code review
6. Merge to main (triggers deployment)

### CodeCatalyst Workflow
The workflow includes:
1. **Build Stage**: Build Docker images
2. **Test Stage**: Run unit and integration tests
3. **Security Stage**: Security scanning
4. **Deploy Stage**: Deploy to AWS

## 📈 Scaling

### Horizontal Scaling
- ECS services can be scaled by updating desired count
- ALB distributes traffic across multiple instances
- RDS can be configured for Multi-AZ deployment

### Vertical Scaling
- Update ECS task CPU and memory
- Upgrade RDS instance class
- Increase ALB capacity

## 🆘 Support

### Getting Help
1. Check the troubleshooting section
2. Review API documentation
3. Check CloudWatch logs
4. Create an issue in the repository

### Useful Commands
```bash
# Get deployment information
./scripts/deploy.sh info

# Check application health
curl http://your-alb-url/health

# View recent logs
aws logs tail /ecs/production-blog-backend --follow
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 