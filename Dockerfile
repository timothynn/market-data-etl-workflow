FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY etl_pipeline.py .
COPY sql/ ./sql/

# Create non-root user
RUN useradd -m -u 1000 etluser && \
    chown -R etluser:etluser /app

USER etluser

CMD ["python", "etl_pipeline.py"]
