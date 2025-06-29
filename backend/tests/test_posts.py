import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.main import app
from app.database import get_db, Base
from app.models.user import User
from app.models.post import Post
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


@pytest.fixture
def test_post():
    """Test post fixture"""
    return {
        "title": "Test Post",
        "content": "This is a test post content.",
        "is_published": True
    }


@pytest.fixture
def auth_headers(client, test_user):
    """Get authentication headers"""
    # Create user and get token
    client.post("/api/auth/signup", json=test_user)
    login_response = client.post("/api/auth/login", data={
        "username": test_user["email"],
        "password": test_user["password"]
    })
    token = login_response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_get_posts_empty(client):
    """Test getting posts when none exist"""
    response = client.get("/api/posts/")
    assert response.status_code == 200
    data = response.json()
    assert data["posts"] == []
    assert data["total"] == 0


def test_create_post_unauthorized(client, test_post):
    """Test creating post without authentication"""
    response = client.post("/api/posts/", json=test_post)
    assert response.status_code == 401
    assert "Not authenticated" in response.json()["detail"]


def test_create_post_authorized(client, test_post, auth_headers):
    """Test creating post with authentication"""
    response = client.post("/api/posts/", json=test_post, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == test_post["title"]
    assert data["content"] == test_post["content"]
    assert data["is_published"] == test_post["is_published"]
    assert "id" in data
    assert "author" in data


def test_get_post_by_id(client, test_post, auth_headers):
    """Test getting a specific post by ID"""
    # Create post first
    create_response = client.post("/api/posts/", json=test_post, headers=auth_headers)
    post_id = create_response.json()["id"]
    
    # Get the post
    response = client.get(f"/api/posts/{post_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == post_id
    assert data["title"] == test_post["title"]


def test_get_post_not_found(client):
    """Test getting a non-existent post"""
    response = client.get("/api/posts/999")
    assert response.status_code == 404
    assert "Post not found" in response.json()["detail"]


def test_update_post_unauthorized(client, test_post, auth_headers):
    """Test updating post without authentication"""
    # Create post first
    create_response = client.post("/api/posts/", json=test_post, headers=auth_headers)
    post_id = create_response.json()["id"]
    
    # Try to update without auth
    update_data = {"title": "Updated Title"}
    response = client.put(f"/api/posts/{post_id}", json=update_data)
    assert response.status_code == 401


def test_update_post_authorized(client, test_post, auth_headers):
    """Test updating post with authentication"""
    # Create post first
    create_response = client.post("/api/posts/", json=test_post, headers=auth_headers)
    post_id = create_response.json()["id"]
    
    # Update the post
    update_data = {"title": "Updated Title", "content": "Updated content"}
    response = client.put(f"/api/posts/{post_id}", json=update_data, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Title"
    assert data["content"] == "Updated content"


def test_delete_post_unauthorized(client, test_post, auth_headers):
    """Test deleting post without authentication"""
    # Create post first
    create_response = client.post("/api/posts/", json=test_post, headers=auth_headers)
    post_id = create_response.json()["id"]
    
    # Try to delete without auth
    response = client.delete(f"/api/posts/{post_id}")
    assert response.status_code == 401


def test_delete_post_authorized(client, test_post, auth_headers):
    """Test deleting post with authentication"""
    # Create post first
    create_response = client.post("/api/posts/", json=test_post, headers=auth_headers)
    post_id = create_response.json()["id"]
    
    # Delete the post
    response = client.delete(f"/api/posts/{post_id}", headers=auth_headers)
    assert response.status_code == 204
    
    # Verify post is deleted
    get_response = client.get(f"/api/posts/{post_id}")
    assert get_response.status_code == 404


def test_posts_pagination(client, auth_headers):
    """Test posts pagination"""
    # Create multiple posts
    for i in range(15):
        post_data = {
            "title": f"Post {i}",
            "content": f"Content for post {i}",
            "is_published": True
        }
        client.post("/api/posts/", json=post_data, headers=auth_headers)
    
    # Test pagination
    response = client.get("/api/posts/?skip=0&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert len(data["posts"]) == 10
    assert data["total"] == 15
    assert data["page"] == 1
    assert data["per_page"] == 10
    
    # Test second page
    response = client.get("/api/posts/?skip=10&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert len(data["posts"]) == 5
    assert data["page"] == 2 