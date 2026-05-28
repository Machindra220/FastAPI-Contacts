# ---------------- Stage 1: Build Dependencies ----------------
# Use the official lightweight Python 3.13 slim image as the base for building
FROM python:3.12-slim AS builder

# Set the working directory inside the container to /app
WORKDIR /app

# Install system dependencies required for psycopg2
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements.txt first (leveraging Docker layer caching)
COPY requirements.txt .

# Install Python dependencies into /install (accessible by any user)
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ---------------- Stage 2: Final Runtime Image ----------------
# Use another slim Python image for the final container (smaller, secure)
FROM python:3.12-slim

# Set the working directory again in the final image
WORKDIR /app

# Install only runtime library (not gcc/build-essential — smaller image)
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user BEFORE copying files so we can set ownership
RUN adduser --disabled-password --gecos "" appuser

# Copy installed dependencies from builder into a system-level path
COPY --from=builder /install /usr/local

# Copy the application code and set ownership to appuser
COPY --chown=appuser:appuser . .

# Remove .env if accidentally copied — secrets must come from runtime environment
RUN rm -f .env

# Switch to the non-root user
USER appuser

# Expose port 8000 so Kubernetes/host can map traffic
EXPOSE 8000

# Run the app using Gunicorn with Uvicorn workers (production-grade server)
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "main:app", "--bind", "0.0.0.0:8000"]

# Wrap your server execution initialization using ddtrace-run
CMD ["ddtrace-run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]