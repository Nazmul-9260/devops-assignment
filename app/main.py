import os
import sys
import json
import time
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# 1. Configuration from Environment Variables
PORT = int(os.getenv("PORT", "8080"))
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
APP_ENV = os.getenv("APP_ENV", "local")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

# 2. Structured JSON Logger setup (outputs to stdout)
class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "message": record.getMessage(),
            "environment": APP_ENV,
            "version": APP_VERSION,
        }
        if hasattr(record, "extra_data"):
            log_record.update(record.extra_data)
        return json.dumps(log_record)

logger = logging.getLogger("devops-app")
logger.setLevel(LOG_LEVEL)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JSONFormatter())
logger.handlers = [handler]

# 3. Prometheus Metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "http_status"]
)
ERROR_COUNT = Counter(
    "http_request_errors_total",
    "Total number of HTTP 5xx/4xx error responses",
    ["method", "endpoint", "http_status"]
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"]
)

# 4. Graceful Startup & Shutdown Lifespan
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Application starting up...", extra={"extra_data": {"port": PORT}})
    yield
    logger.info("Received shutdown signal (SIGTERM/SIGINT). Shutting down gracefully...")

app = FastAPI(title="DevOps Assessment Service", version=APP_VERSION, lifespan=lifespan)

# 5. Middleware for Metrics and Request Logging
@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    endpoint = request.url.path
    method = request.method
    status = str(response.status_code)

    # Skip recording /metrics scrape itself to keep metrics clean
    if endpoint != "/metrics":
        REQUEST_COUNT.labels(method=method, endpoint=endpoint, http_status=status).inc()
        REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(duration)
        if response.status_code >= 400:
            ERROR_COUNT.labels(method=method, endpoint=endpoint, http_status=status).inc()

        logger.info(
            "Request processed",
            extra={
                "extra_data": {
                    "method": method,
                    "path": endpoint,
                    "status_code": response.status_code,
                    "duration_ms": round(duration * 1000, 2),
                }
            },
        )
    return response

# 6. Endpoints
@app.get("/")
def read_root():
    return {
        "message": "Hello from DevOps Task!",
        "status": "running",
        "version": APP_VERSION
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, log_config=None)


# Hi iam nazmul
#file1
