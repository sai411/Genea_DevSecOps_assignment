import os
import pymysql
from pathlib import Path

conn = pymysql.connect(
    host=os.getenv("DB_HOST"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_NAME"),
    port=int(os.getenv("DB_PORT", "3306")),
    autocommit=False
)

cursor = conn.cursor()

try:
    for sql_file in sorted(Path("sql").glob("*.sql")):
        print(f"Running migration: {sql_file.name}")

        with open(sql_file) as f:
            sql = f.read().strip()
            if sql:
                cursor.execute(sql)

    conn.commit()
    print("Database migrations applied successfully")

except Exception as e:
    conn.rollback()
    print("Migration failed. Rolled back.")
    raise

finally:
    cursor.close()
    conn.close()
