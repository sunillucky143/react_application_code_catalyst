from pydantic_settings import BaseSettings
from typing import List
import os
import json


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://bloguser:blogpassword@localhost:5432/blogdb"
    
    # JWT
    jwt_secret: str = "your-super-secret-jwt-key-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expiration: int = 3600
    
    # CORS
    cors_origins: str = '["http://localhost:3000", "http://127.0.0.1:3000"]'
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins string to list"""
        try:
            return json.loads(self.cors_origins)
        except (json.JSONDecodeError, TypeError):
            # Fallback to default if parsing fails
            return ["http://localhost:3000", "http://127.0.0.1:3000"]
    
    # Application
    debug: bool = True
    environment: str = "development"
    api_prefix: str = "/api"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings() 