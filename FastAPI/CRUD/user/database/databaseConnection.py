from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import config
DATABASE_URL = config.databaseConnectionString["connectionString"]

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False,autoflush=False,bind=engine)
Base = declarative_base()

def get_db():
    db = None
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()