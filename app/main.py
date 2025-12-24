import os
import psycopg2
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_PORT = os.getenv("DB_PORT", "5432")


def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
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
        cursor = conn.cursor()

        cursor.execute("SELECT id, name, email FROM users;")
        rows = cursor.fetchall()

        users = []
        for row in rows:
            users.append({
                "id": row[0],
                "name": row[1],
                "email": row[2]
            })

        cursor.close()
        conn.close()

        return users

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/user_add", status_code=201)
def add_user(user: UserCreate):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            "INSERT INTO users (name, email) VALUES (%s, %s);",
            (user.name, user.email)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return {"message": "User added successfully"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
