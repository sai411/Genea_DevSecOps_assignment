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
            statements = f.read().split(";")

            for stmt in statements:
                stmt = stmt.strip()
                if not stmt:
                    continue

                try:
                    cursor.execute(stmt)

                except pymysql.err.ProgrammingError as e:
                    if e.args[0] in (1050, 1060, 1146):
                        print(f"Skipping (already applied or dependency missing): {stmt}")
                    else:
                        raise

    conn.commit()
    print("Database migrations applied successfully")

except Exception:
    conn.rollback()
    print("Migration failed. Rolled back.")
    raise

finally:
    cursor.close()
    conn.close()
