from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, Form
from ..database import get_db
from ..schemas.post import PostCreate, PostUpdate, PostResponse, PostList
from ..utils.auth import get_current_active_user
from ..storage import posts, post_id_counter

router = APIRouter(prefix="/posts", tags=["posts"])

@router.get("/", response_model=PostList)
def get_posts(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    db=Depends(get_db)
):
    """Get all published posts with pagination"""
    # Filter published posts
    published_posts = [post for post in posts.values() if post["is_published"]]
    total = len(published_posts)
    
    # Apply pagination
    paginated_posts = published_posts[skip:skip+limit]
    
    return PostList(
        posts=paginated_posts,
        total=total,
        page=skip // limit + 1 if limit > 0 else 1,
        per_page=limit
    )


@router.post("/", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post(
    post: PostCreate,
    current_user: dict = Depends(get_current_active_user),
    db=Depends(get_db)
):
    """Create a new post (authenticated users only)"""
    global post_id_counter
    post_id_counter += 1
    
    post_data = post.dict()
    post_data["id"] = post_id_counter
    post_data["author_id"] = current_user["id"]
    post_data["author"] = {
        "id": current_user["id"],
        "username": current_user["username"],
        "email": current_user["email"]
    }
    post_data["created_at"] = "2023-01-01T00:00:00"
    post_data["updated_at"] = "2023-01-01T00:00:00"
    
    posts[post_id_counter] = post_data
    
    return post_data


@router.get("/{post_id}", response_model=PostResponse)
def get_post(post_id: int, db=Depends(get_db)):
    """Get a specific post by ID"""
    post = posts.get(post_id)
    
    if not post or not post["is_published"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    return post


@router.put("/{post_id}", response_model=PostResponse)
def update_post(
    post_id: int,
    post_update: PostUpdate,
    current_user: dict = Depends(get_current_active_user),
    db=Depends(get_db)
):
    """Update a post (only the author can update)"""
    if post_id not in posts:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    post = posts[post_id]
    
    if post["author_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this post"
        )
    
    # Update only provided fields
    update_data = post_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        post[field] = value
    
    post["updated_at"] = "2023-01-01T00:00:00"
    
    return post


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: int,
    current_user: dict = Depends(get_current_active_user),
    db=Depends(get_db)
):
    """Delete a post (only the author can delete)"""
    if post_id not in posts:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    post = posts[post_id]
    
    if post["author_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this post"
        )
    
    del posts[post_id]
    
    return None