# ---------------- Stage 1: Build Dependencies ----------------
# Use the official lightweight Python 3.15 slim image as the base for building
FROM python:3.15-slim AS builder

# Set the working directory inside the container to /app
WORKDIR /app

# Copy only requirements.txt first (leveraging Docker layer caching)
COPY requirements.txt .

# Install Python dependencies into the builder image (user space to keep it clean)
RUN pip install --user --no-cache-dir -r requirements.txt


# ---------------- Stage 2: Final Runtime Image ----------------
# Use another slim Python image for the final container (smaller, secure)
FROM python:3.15-slim

# Set the working directory again in the final image
WORKDIR /app

# Copy installed dependencies from builder stage into final image
COPY --from=builder /root/.local /root/.local

# Update PATH so Python can find the installed packages
ENV PATH=/root/.local/bin:$PATH

# Copy the rest of the application code into the container
COPY . .

# Create a non-root user for security best practices
RUN adduser --disabled-password appuser

# Switch to the non-root user
USER appuser

# Expose port 8000 so Kubernetes/host can map traffic
EXPOSE 8000

# Run the app using Gunicorn with Uvicorn workers (production-grade server)
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "main:app", "--bind", "0.0.0.0:8000"]
