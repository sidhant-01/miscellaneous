from fastapi import FastAPI, HTTPException
from fastapi.params import Depends, Header
from starlette.responses import StreamingResponse
from user.models.schemas import insertUser, userDetails, updateUser
from sqlalchemy.orm import Session
from user.database import databaseConnection
from typing import List, Optional
from user.crud import crud
from authorizer import authorizer
from config import homePage

app = FastAPI()

@app.get("/")
async def get_endpoints():
     return homePage

@app.get("/getallusers", response_model=List[userDetails])
async def get_all_users(Authorization: str = Header(...),db: Session = Depends(databaseConnection.get_db)):
    role = authorizer.validate_jwt(Authorization)
    if (role == "Read") or (role == "Write") or (role == "Admin"): 
        all_Users = crud.get_all_users(db)
        return all_Users
    raise HTTPException(status_code=401,detail=f"You are not authorized to fetch users !!")

@app.get("/getuser/{id}",response_model=userDetails)
async def get_user(id: int, Authorization: str = Header(...),db: Session = Depends(databaseConnection.get_db)):
    role = authorizer.validate_jwt(Authorization)
    if (role == "Read") or (role == "Write") or (role == "Admin"): 
        get_user = crud.get_user(db,id)
        if not get_user:
            raise HTTPException(status_code=404, detail=f"user with ID {id} does not exists !!")
        return get_user
    raise HTTPException(status_code=401,detail=f"You are not authorized to fetch users !!")

@app.post("/createuser",status_code=201,response_model=userDetails)
async def create_user(create_user: insertUser,Authorization: str = Header(...),db: Session = Depends(databaseConnection.get_db)):
    role = authorizer.validate_jwt(Authorization)
    if (role == "Write") or (role == "Admin"):
        create_users = crud.create_user(db,create_user)
        if not create_users:
            raise HTTPException(status_code=409, detail=f"email ID {create_user.Email} is already registered !!")
        return create_users
    raise HTTPException(status_code=401,detail=f"You are not authorized to create users !!")

@app.delete("/deleteuser/{id}", response_model=userDetails)
async def delete_user(id: int,Authorization: str = Header(...), db: Session = Depends(databaseConnection.get_db)):
    role = authorizer.validate_jwt(Authorization)
    if role == "Admin":
        deleted_user = crud.delete_user(db, id)
        if not deleted_user:
            raise HTTPException(status_code=404, detail=f"user with id {id} does not exists !!")
        return deleted_user
    raise HTTPException(status_code=401,detail=f"You are not authorized to delete users !!")

@app.patch("/updateuser", response_model=updateUser)
async def update_user(update_user: updateUser, Authorization: str = Header(...),db: Session = Depends(databaseConnection.get_db)):
    role = authorizer.validate_jwt(Authorization)
    if (role == "Write") or (role == "Admin"):
        updated_user = crud.update_user(db, update_user)
        if not updated_user:
            raise HTTPException(status_code=404, detail=f"user with id {update_user.ID} does not exists !!")
        return updated_user
    raise HTTPException(status_code=401,detail=f"You are not authorized to update users !!")