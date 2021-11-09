homePage = {
        "availableEndpoints": {
            "get_user": "/getuser",
            "get_all_users": "/getallusers",
            "create_user": "/createuser",
            "delete_user": "deleteuser/<id_of_user>",
            "update_user": "/updateuser"
        }
    }

token = {

    "openID_URI": "https://login.microsoftonline.com/common/discovery/keys",
    "tokenIssuer": "https://sts.windows.net/311d38d8-2104-46af-9df1-269cac3940d7/",
    "tokenAudience": "add4f80c-0f85-48f8-9087-1d01f57ab774",
    "roles": [
        "Read",
        "Write",
        "Admin"
    ]
}

databaseConnectionString = {

    "connectionString": "mysql+mysqlconnector://root:Password123@localhost:3306/usersdb"
}

redis = {
    "host": 'localhost',
    "port": 6379
}