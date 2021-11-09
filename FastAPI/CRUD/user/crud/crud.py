from sqlalchemy.sql.expression import update
from sqlalchemy.sql.functions import user
from ..models.models import userTable

def get_all_users(db):
    return db.query(userTable).all()

def get_user(db,id: int):
    return db.query(userTable).filter(userTable.ID == id).first()

def create_user(db,create_user):
    new_user = ""
    userEmail = db.query(userTable).filter(userTable.Email == create_user.Email).first()
    if not userEmail:
        new_user = userTable(UserName=create_user.UserName,UserPassword=create_user.UserPassword,Email=create_user.Email,Location=create_user.Location,City=create_user.City,Salary=create_user.Salary)
        db.add(new_user)
        db.commit()
    return new_user

def delete_user(db,id: int):
    user = db.query(userTable).filter(userTable.ID == id).first()
    if not user:
        return None
    db.delete(user)
    db.commit()
    return user

def update_user(db,update_user):
    db.query(userTable).filter(userTable.ID == update_user.ID).update({"UserName": update_user.UserName,"UserPassword": update_user.UserPassword,"Email": update_user.Email,"Location": update_user.Location, "City": update_user.City,"Salary":update_user.Salary}, synchronize_session = False)
    db.commit()
    updated_user = db.query(userTable).filter(userTable.ID == update_user.ID).first()
    return updated_user
