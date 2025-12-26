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
            for stmt in f.read().split(";"):
                stmt = stmt.strip()
                if stmt:
                    cursor.execute(stmt)

    conn.commit()
    print("Database migrations applied successfully")

except Exception:
    conn.rollback()
    raise

finally:
    cursor.close()
    conn.close()
