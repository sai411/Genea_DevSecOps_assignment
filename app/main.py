import os
import pymysql
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_PORT = int(os.getenv("DB_PORT", "3306"))


def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        port=DB_PORT,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
    )


class UserCreate(BaseModel):
    name: str
    email: str


@app.get("/health")
def health_check():
    return {"status": "OK"}


@app.get("/users")
def get_users():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, name, email FROM users;")
            users = cursor.fetchall()

        conn.close()
        return users

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/user_add", status_code=201)
def add_user(user: UserCreate):
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO users (name, email) VALUES (%s, %s);",
                (user.name, user.email)
            )

        conn.close()
        return {"message": "User added successfully"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
