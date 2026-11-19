# DevOps Engineer Candidate Assessment & Implementation Portfolio

This repository contains the end-to-end implementation, containerization, Kubernetes orchestration, infrastructure monitoring, and automated alerting system for the DevOps Engineer Technical Assessment.

---

## 🏗️ Architecture & Tech Stack

* **Orchestration & Containerization:** Kubernetes (`v1.37.1`), Docker, Docker Hub, Helm (`v3`).
* **Observability & Monitoring:** Prometheus, Grafana, Alertmanager (`kube-prometheus-stack`), Node Exporter (`v1.8.2`).
* **Networking & Security:** Nginx Ingress Controller, TLS 1.2+ (Self-Signed SSL), MetalLB / LoadBalancer service routing.
* **Scripting & Automation:** Bash (Production telemetry scripts with JSON output and log rotation).

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Kubernetes Monitoring Stack (Prometheus & Grafana)
Deployed the `kube-prometheus-stack` Helm chart inside the `monitoring` namespace to handle cluster metrics and observability.

```bash
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo update

kubectl create namespace monitoring

helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.service.type=LoadBalancer \
  --set grafana.adminPassword='YourSecurePassword'
