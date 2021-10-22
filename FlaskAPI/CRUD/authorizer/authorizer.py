import jwt
from pydantic.networks import HttpUrl
import requests
import base64
from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicNumbers
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from fastapi import HTTPException
import config

try:
    response = requests.get(config.token["openID_URI"])
    formatted_response = response.json()
except:
    raise HTTPException(status_code=500,detail=f"unable to get public keys from azure open id")
issuer = config.token["tokenIssuer"] 
valid_audiences = "api://" + config.token["tokenAudience"]


def get_kid(token):
    headers = jwt.get_unverified_header(token)
    return headers["kid"]

def get_jwk(kid):
    for keys in formatted_response["keys"]:
        if keys["kid"] == kid:
            return keys

def ensure_bytes(key):
    if isinstance(key, str):
        key = key.encode('utf-8')
        return key

def decode_value(val):
    decoded = base64.urlsafe_b64decode(ensure_bytes(val) + b'==')
    return int.from_bytes(decoded, 'big')

def rsa_pem_from_jwk(jwk):
        return RSAPublicNumbers(
        n=decode_value(jwk['n']),
        e=decode_value(jwk['e'])
        ).public_key(default_backend()).public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
def validate_jwt(token):
    try:
        public_key = rsa_pem_from_jwk(get_jwk(get_kid(token)))
        decoded_token = jwt.decode(token,
                         public_key,
                         verify=True,
                         algorithms=['RS256'],
                         audience=valid_audiences,
                         issuer=issuer)
        role = check_permissions(decoded_token)
        return role
    except:
        raise HTTPException(status_code=401, detail=f"Invalid Token")
def check_permissions(decoded_token):
    token_roles = decoded_token.get('roles')
    for role in token_roles:
        for permittedRole in config.token["roles"]:
            if permittedRole == role:
                return role




            