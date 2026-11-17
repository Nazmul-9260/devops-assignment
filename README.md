# DevOps Engineer Technical Assessment

A production-ready, observable, and containerized web service deployed with a full CI/CD pipeline, Infrastructure as Code (Terraform), Kubernetes manifests, and a complete Prometheus/Grafana/Loki monitoring stack.

---

## 📂 Project Structure

```text
devops-assessment/
├── app/
│   ├── main.py              # FastAPI application (Endpoints, JSON logging, Metrics)
│   ├── test_main.py         # Pytest unit tests
│   └── requirements.txt     # Python dependencies
├── .github/workflows/       # GitHub Actions CI/CD pipelines
├── terraform/               # AWS Infrastructure as Code (EC2, IAM, S3 backend)
├── k8s/                     # Kubernetes manifests, HPA, and ConfigMaps
├── monitoring/              # Prometheus, Grafana, Loki, and Alloy configurations
├── scripts/                 # Linux system health monitoring and log rotation script
├── Dockerfile               # Multi-stage production-grade Dockerfile
├── .dockerignore            # Files ignored during Docker build
├── docker-compose.yml       # Local app and observability stack compose setup
└── README.md                # Project documentation


docker compose up -d --build
docker compose ps


[nazmul@stg-mf-dcs ~]$ curl http://localhost:8080/
{"message":"Hello from DevOps Task!","status":"running","version":"1.0.0"}[nazmul@stg-mf-dcs ~]$

nazmul@stg-mf-dcs ~]$ curl http://localhost:8080/health
{"status":"healthy"}[nazmul@stg-mf-dcs ~]$



{"status":"healthy"}[nazmul@stg-mf-dcs ~]$ curl http://localhost:8080/metrics
# HELP python_gc_objects_collected_total Objects collected during gc
# TYPE python_gc_objects_collected_total counter
python_gc_objects_collected_total{generation="0"} 1230.0
python_gc_objects_collected_total{generation="1"} 21.0
python_gc_objects_collected_total{generation="2"} 0.0
# HELP python_gc_objects_uncollectable_total Uncollectable objects found during GC
# TYPE python_gc_objects_uncollectable_total counter
python_gc_objects_uncollectable_total{generation="0"} 0.0
python_gc_objects_uncollectable_total{generation="1"} 0.0
python_gc_objects_uncollectable_total{generation="2"} 0.0





