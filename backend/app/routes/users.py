from fastapi import APIRouter, Depends, HTTPException, status
from ..database import get_db
from ..schemas.user import UserResponse, UserUpdate
from ..utils.auth import get_current_active_user, get_password_hash
from ..storage import users  # Import the in-memory users dictionary

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: dict = Depends(get_current_active_user)):
    """Get current user profile"""
    return current_user


@router.put("/me", response_model=UserResponse)
def update_current_user_profile(
    user_update: UserUpdate,
    current_user: dict = Depends(get_current_active_user),
    db=Depends(get_db)
):
    """Update current user profile"""
    # Check if email is being changed and if it's already taken
    if user_update.email and user_update.email != current_user["email"]:
        if user_update.email in users:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    # Check if username is being changed and if it's already taken
    if user_update.username and user_update.username != current_user["username"]:
        for existing_user in users.values():
            if existing_user["username"] == user_update.username:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already taken"
                )
    
    # Update user fields
    update_data = user_update.dict(exclude_unset=True)
    
    # Hash password if it's being updated
    if "password" in update_data:
        update_data["hashed_password"] = get_password_hash(update_data.pop("password"))
    
    # Update the user in the in-memory dictionary
    for field, value in update_data.items():
        current_user[field] = value
    
    # If email is changed, update the dictionary key
    if "email" in update_data and update_data["email"] != current_user["email"]:
        old_email = current_user["email"]
        users[update_data["email"]] = current_user
        del users[old_email]
    
    return current_user