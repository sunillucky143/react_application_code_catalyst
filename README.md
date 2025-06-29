# Full-Stack Blog Application with AWS CodeCatalyst

A production-grade blog application built with React (frontend) and FastAPI (backend), fully integrated with AWS CodeCatalyst for CI/CD, infrastructure management, and deployment automation.

## 🏗️ Architecture

- **Frontend**: React SPA with React Router and Context API
- **Backend**: FastAPI with JWT authentication and PostgreSQL
- **Database**: PostgreSQL (Docker for dev, RDS for production)
- **Infrastructure**: AWS ECS Fargate, ALB, RDS, ECR
- **CI/CD**: AWS CodeCatalyst workflows
- **Containerization**: Docker with docker-compose for local development

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Python 3.9+
- Docker and Docker Compose
- AWS CLI configured
- AWS CodeCatalyst access

### Local Development

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd react_application_code_catalyst
   ```

2. **Environment setup**:
   ```bash
   # Backend
   cp backend/.env.example backend/.env
   # Frontend
   cp frontend/.env.example frontend/.env
   ```

3. **Start with Docker Compose**:
   ```bash
   docker-compose up --build
   ```

4. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - Database: localhost:5432

### Manual Development Setup

#### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### Frontend
```bash
cd frontend
npm install
npm start
```

## 🏛️ Project Structure

```
react_application_code_catalyst/
├── frontend/                 # React SPA
│   ├── public/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── context/
│   │   ├── services/
│   │   └── utils/
│   ├── package.json
│   └── Dockerfile
├── backend/                  # FastAPI application
│   ├── app/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── utils/
│   ├── requirements.txt
│   └── Dockerfile
├── infrastructure/           # IaC templates
│   ├── cloudformation/
│   └── terraform/
├── .codecatalyst/           # CodeCatalyst workflows
│   └── workflows/
├── docker-compose.yaml
└── README.md
```

## 🔐 Authentication

The application uses JWT-based authentication:

1. **Sign up**: POST `/api/signup`
2. **Login**: POST `/api/login`
3. **Protected routes**: Include `Authorization: Bearer <token>` header

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

## 🚀 Deployment with CodeCatalyst

### Prerequisites

1. **CodeCatalyst Setup**:
   - Create a CodeCatalyst space and project
   - Connect your source repository
   - Set up environment variables and secrets

2. **Required Environment Variables**:
   - `AWS_REGION`
   - `DATABASE_URL`
   - `JWT_SECRET`
   - `ECR_REPOSITORY_URI`

### Deployment Process

1. **Push to main branch** triggers the workflow
2. **Build stage**: Builds and pushes Docker images to ECR
3. **Test stage**: Runs unit and integration tests
4. **Deploy stage**: Deploys infrastructure and application

### Manual Deployment

```bash
# Deploy infrastructure
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/main.yaml \
  --stack-name blog-app-stack \
  --capabilities CAPABILITY_IAM

# Deploy application
aws ecs update-service \
  --cluster blog-app-cluster \
  --service blog-app-service \
  --force-new-deployment
```

## 📊 Monitoring and Logs

- **Application Logs**: CloudWatch Logs
- **Metrics**: CloudWatch Metrics
- **Health Checks**: ALB health checks
- **API Monitoring**: API Gateway metrics

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```
DATABASE_URL=postgresql://user:password@localhost:5432/blogdb
JWT_SECRET=your-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRATION=3600
CORS_ORIGINS=http://localhost:3000
```

#### Frontend (.env)
```
REACT_APP_API_URL=http://localhost:8000
REACT_APP_ENVIRONMENT=development
```

## 🛠️ Development Workflow

1. **Feature Development**:
   - Create feature branch from main
   - Implement changes
   - Write tests
   - Create pull request

2. **Code Review**:
   - Automated tests run on PR
   - Code review required
   - Merge to main triggers deployment

3. **Deployment**:
   - Automatic deployment to staging
   - Manual approval for production
   - Blue-green deployment strategy

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection**:
   ```bash
   # Check if PostgreSQL is running
   docker ps | grep postgres
   ```

2. **Frontend Build Issues**:
   ```bash
   # Clear npm cache
   npm cache clean --force
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **Backend Import Errors**:
   ```bash
   # Check Python path
   export PYTHONPATH="${PYTHONPATH}:$(pwd)"
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

- **Interactive API Docs**: http://localhost:8000/docs
- **OpenAPI Schema**: http://localhost:8000/openapi.json

### Key Endpoints

- `GET /api/posts` - List all posts
- `POST /api/posts` - Create new post (authenticated)
- `GET /api/posts/{id}` - Get single post
- `PUT /api/posts/{id}` - Update post (authenticated)
- `DELETE /api/posts/{id}` - Delete post (authenticated)
- `POST /api/signup` - User registration
- `POST /api/login` - User authentication
- `GET /api/me` - Get current user (authenticated)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the API documentation

## 🔄 Updates and Maintenance

- Regular security updates
- Dependency updates via Dependabot
- Infrastructure updates via CodeCatalyst workflows
- Database migrations handled automatically 