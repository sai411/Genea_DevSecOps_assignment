import os
import pymysql
from pathlib import Path

DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")
DB_PORT = int(os.getenv("DB_PORT", "3306"))

MIGRATIONS_DIR = Path("sql")

conn = pymysql.connect(
    host=DB_HOST,
    user=DB_USER,
    password=DB_PASSWORD,
    database=DB_NAME,
    port=DB_PORT,
    autocommit=False
)

cursor = conn.cursor()

try:
    migration_files = sorted(MIGRATIONS_DIR.glob("*.sql"))

    if not migration_files:
        print("No migration files found. Exiting.")
    else:
        for file in migration_files:
            print(f"Running migration: {file.name}")
            with open(file, "r") as f:
                sql = f.read()
                cursor.execute(sql)

        conn.commit()
        print("All database migrations applied successfully")

except Exception as e:
    conn.rollback()
    print("Migration failed. Rolled back.")
    raise e

finally:
    cursor.close()
    conn.close()
