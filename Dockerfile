# Stage 1: Builder
FROM python:3.12.6-slim AS builder

WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime (Minimal Slim Image)
FROM python:3.12.6-slim

LABEL org.opencontainers.image.title="devops-assessment-app" \
      org.opencontainers.image.description="Production-ready Python FastAPI web service" \
      org.opencontainers.image.version="1.0.0"

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup -u 1001 appuser

WORKDIR /app

# Copy installed dependencies and application code
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup app/ .

# Environment defaults
ENV PORT=8080 \
    LOG_LEVEL=INFO \
    APP_ENV=production \
    APP_VERSION=1.0.0 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER appuser

EXPOSE 8080

# Built-in Python healthcheck (no curl needed, keeps image small)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--no-access-log"]
