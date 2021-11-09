from pydantic import BaseModel
from typing import Optional

class userDetails(BaseModel):
    ID: int
    UserName: str

    class Config:
        orm_mode = True

class insertUser(BaseModel):
    UserName: str
    Email: str
    UserPassword: str
    Salary: str
    City: str
    Location: str

class deleteUser(BaseModel):
    ID: int

    class Config:
        orm_mode = True

class updateUser(BaseModel):
    ID: int
    UserName: str
    Email: str
    UserPassword: str
    Salary: str
    City: str
    Location: str

    class Config:
        orm_mode = True
      
