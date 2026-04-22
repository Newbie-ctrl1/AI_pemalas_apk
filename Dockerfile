FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./

CMD ["sh", "-c", "gunicorn app.main:app --bind 0.0.0.0:${PORT:-8080} --workers 2 --threads 4 --timeout 120"]
