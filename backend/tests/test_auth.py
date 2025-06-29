import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.main import app
from app.database import get_db, Base
from app.models.user import User
from app.utils.auth import get_password_hash


# Create in-memory SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    """Override database dependency for testing"""
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture
def client():
    """Test client fixture"""
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as c:
        yield c
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def test_user():
    """Test user fixture"""
    return {
        "email": "test@example.com",
        "username": "testuser",
        "password": "testpassword123"
    }


def test_signup_success(client, test_user):
    """Test successful user signup"""
    response = client.post("/api/auth/signup", json=test_user)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == test_user["email"]
    assert data["username"] == test_user["username"]
    assert "id" in data
    assert "hashed_password" not in data


def test_signup_duplicate_email(client, test_user):
    """Test signup with duplicate email"""
    # First signup
    client.post("/api/auth/signup", json=test_user)
    
    # Second signup with same email
    response = client.post("/api/auth/signup", json=test_user)
    assert response.status_code == 400
    assert "Email already registered" in response.json()["detail"]


def test_login_success(client, test_user):
    """Test successful login"""
    # Create user first
    client.post("/api/auth/signup", json=test_user)
    
    # Login
    response = client.post("/api/auth/login", data={
        "username": test_user["email"],
        "password": test_user["password"]
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_invalid_credentials(client, test_user):
    """Test login with invalid credentials"""
    # Create user first
    client.post("/api/auth/signup", json=test_user)
    
    # Login with wrong password
    response = client.post("/api/auth/login", data={
        "username": test_user["email"],
        "password": "wrongpassword"
    })
    assert response.status_code == 401
    assert "Incorrect email or password" in response.json()["detail"]


def test_protected_route_unauthorized(client):
    """Test accessing protected route without authentication"""
    response = client.get("/api/users/me")
    assert response.status_code == 401
    assert "Not authenticated" in response.json()["detail"]


def test_protected_route_authorized(client, test_user):
    """Test accessing protected route with authentication"""
    # Create user and get token
    client.post("/api/auth/signup", json=test_user)
    login_response = client.post("/api/auth/login", data={
        "username": test_user["email"],
        "password": test_user["password"]
    })
    token = login_response.json()["access_token"]
    
    # Access protected route
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/api/users/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == test_user["email"]
    assert data["username"] == test_user["username"] 