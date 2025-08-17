# syntax=docker/dockerfile:1

FROM python:3.11

WORKDIR /code

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

COPY . .

EXPOSE 8081

CMD ["gunicorn", "--bind", "0.0.0.0:8081", "main:app", "--worker-class", "uvicorn.workers.UvicornWorker"]
