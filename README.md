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
   cd blog-application
   ```

2. **Environment setup**:
   ```bash
   # Backend
   cp backend/env.example backend/.env
   # Frontend
   cp frontend/env.example frontend/.env
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
blog-application/
├── frontend/                 # React SPA
│   ├── public/               # Public assets
│   ├── src/                  # Source code
│   │   ├── components/       # React components
│   │   ├── pages/            # Page components
│   │   ├── context/          # React context providers
│   │   ├── services/         # API services
│   │   └── utils/            # Utility functions
│   ├── package.json          # NPM dependencies
│   ├── Dockerfile            # Frontend Docker configuration
│   └── env.example           # Example environment variables
├── backend/                  # FastAPI application
│   ├── app/                  # Application code
│   │   ├── models/           # Database models
│   │   ├── routes/           # API routes
│   │   ├── services/         # Business logic
│   │   └── utils/            # Utility functions
│   ├── requirements.txt      # Python dependencies
│   ├── Dockerfile            # Backend Docker configuration
│   └── env.example           # Example environment variables
├── infrastructure/           # IaC templates
│   └── cloudformation/       # CloudFormation templates
├── .codecatalyst/            # CodeCatalyst configuration
│   └── workflows/            # CI/CD workflow definitions
│       └── main.yaml         # Main workflow file
├── scripts/                  # Utility scripts
│   └── deploy.sh             # Deployment script
├── docker-compose.yaml       # Local development setup
├── README.md                 # Project documentation
└── SETUP.md                  # Detailed setup instructions
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
   - `AWS_REGION`: Your AWS region (e.g., us-east-1)
   - `AWS_ACCOUNT_ID`: Your AWS account ID
   - `DATABASE_PASSWORD`: Secure database password

### Deployment Process

The CodeCatalyst workflow (`/.codecatalyst/workflows/main.yaml`) includes:

1. **Build Stage**: 
   - Builds Docker images for frontend and backend
   - Runs in parallel for faster builds

2. **Test Stage**: 
   - Runs unit tests for frontend and backend
   - Performs security scanning

3. **Push to ECR Stage**:
   - Creates ECR repositories if they don't exist (blog-backend and blog-frontend)
   - Tags and pushes Docker images to ECR

4. **Deploy Stage**:
   - Deploys CloudFormation infrastructure
   - Updates ECS services with new container images
   - Runs integration tests

### Code Catalyst Integration

The deployment script has been optimized for AWS Code Catalyst with the following features:

1. **Fixed Repository Names**:
   - Uses standardized repository names: `blog-backend` and `blog-frontend`
   - Simplifies integration with Code Catalyst workflows

2. **Separate Repository URIs**:
   - CloudFormation template now accepts separate parameters for backend and frontend repositories
   - Provides more flexibility and clarity in deployment

3. **Streamlined Image Building**:
   - Builds images with standard tags (`backend:latest` and `frontend:latest`)
   - Tags and pushes to ECR in separate steps for better visibility

4. **Testing Support**:
   - Includes a test script (`scripts/test_deploy.sh`) to verify deployment changes
   - Ensures compatibility with Code Catalyst workflows

### Manual Deployment

You can also deploy manually using the provided script:

```bash
# Set required environment variables
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=123456789012
export DATABASE_PASSWORD=your-secure-password

# Run the deployment script
./scripts/deploy.sh
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

### Feature Development

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Implement Changes**:
   - Write code following project standards
   - Add appropriate documentation
   - Implement unit tests

3. **Test Locally**:
   ```bash
   # Backend tests
   cd backend && pytest
   
   # Frontend tests
   cd frontend && npm test
   ```

4. **Create Pull Request**:
   - Push your branch to the repository
   - Create a pull request with a clear description
   - Reference any related issues

### CI/CD Pipeline

The CodeCatalyst workflow automatically runs when:
- Code is pushed to the main branch
- Pull requests are created or updated

The workflow includes:
1. **Build**: Builds Docker images for frontend and backend
2. **Test**: Runs unit tests and security scans
3. **Deploy**: Deploys to AWS (only on main branch)
   - Infrastructure deployment with CloudFormation
   - Application deployment to ECS Fargate
   - Integration tests to verify deployment

### Best Practices

- Keep pull requests focused on a single feature or fix
- Write meaningful commit messages
- Ensure all tests pass before merging
- Follow the project's coding standards
- Document significant changes in the README or SETUP files

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