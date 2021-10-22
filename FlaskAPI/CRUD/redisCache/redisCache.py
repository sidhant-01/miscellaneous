from redis import Redis
from config import redis
import json

redis_client = Redis(host=redis["host"],port=redis["port"],db=0)


def setCache(keyName,jsonToCache):
    redis_client.set(keyName,json.dumps(jsonToCache))

def getCache(keyName):
    return redis_client.get(keyName)

