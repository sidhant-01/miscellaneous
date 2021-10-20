from sqlalchemy.sql.sqltypes import String
from ..database.databaseConnection import Base
from sqlalchemy import Integer, Column

class userTable(Base):
    __tablename__ = "usersinfo"
    ID = Column(Integer,primary_key=True,index=True)
    UserName = Column(String)
    Email = Column(String)
    UserPassword = Column(String)
    Salary = Column(String)
    City = Column(String)
    Location = Column(String)