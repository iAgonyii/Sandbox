import os
import motor.motor_asyncio
from dotenv import load_dotenv

load_dotenv()
mongoclient = motor.motor_asyncio.AsyncIOMotorClient(f'mongodb://{os.getenv("MONGO_USERNAME")}:{os.getenv("MONGO_PASSWORD")}@localhost:27017/')
db = mongoclient.get_database("database-name")

coll_users = db.get_collection("users")
