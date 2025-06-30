from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import os
from app.config import settings
from app.database import Base
from app.routes import auth_router, posts_router, users_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    print("Starting application...")
    
    # Create uploads directory if it doesn't exist
    os.makedirs("uploads", exist_ok=True)
    print("Application started successfully!")
    
    yield
    
    # Shutdown
    print("Shutting down application...")


# Create FastAPI app
app = FastAPI(
    title="Blog API",
    description="A full-stack blog application API built with FastAPI",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Mount static files for uploaded images
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add trusted host middleware for production
if not settings.debug:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["*"]  # Configure with your domain in production
    )

# Include routers
app.include_router(auth_router, prefix=settings.api_prefix)
app.include_router(posts_router, prefix=settings.api_prefix)
app.include_router(users_router, prefix=settings.api_prefix)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to the Blog API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.get(f"{settings.api_prefix}/health")
async def api_health_check():
    """API health check endpoint"""
    return {"status": "healthy", "api": "online"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug
    )