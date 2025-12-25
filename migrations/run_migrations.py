import os
import pymysql

conn = pymysql.connect(
    host=os.getenv("DB_HOST"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_NAME"),
    port=int(os.getenv("DB_PORT", "3306"))
)

cursor = conn.cursor()

with open("001_create_users_table.sql") as f:
    sql = f.read()
    cursor.execute(sql)

conn.commit()
cursor.close()
conn.close()

print("Database migrations applied successfully")
