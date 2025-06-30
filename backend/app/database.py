from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

# Create a dummy base class for models
Base = declarative_base()

# Create a dummy database session for compatibility
class DummyDB:
    def close(self):
        pass

def get_db():
    """Dependency to get dummy database session"""
    db = DummyDB()
    try:
        yield db
    finally:
        db.close()