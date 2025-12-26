FROM python:3.11-slim

WORKDIR /migrations

RUN pip install pymysql

COPY . .

CMD ["python", "run_migrations.py"]