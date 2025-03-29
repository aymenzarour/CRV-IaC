
# CRV Project - AutoScaling & IaC with Full Monitoring

## Cluster Architecture

The project is deployed on a 4-node K3s Kubernetes cluster, offering a lightweight but powerful environment:

```
NAME      STATUS   ROLES                  INTERNAL-IP       OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master    Ready    control-plane,master   192.168.204.120   Ubuntu 22.04.5 LTS   5.15.0-131-generic   containerd://2.0.2-k3s2
node-01   Ready    <none>                 192.168.204.10    Ubuntu 22.04.3 LTS   6.8.0-45-generic     containerd://2.0.4-k3s2
node-02   Ready    <none>                 192.168.204.20    Ubuntu 22.04.3 LTS   6.8.0-52-generic     containerd://2.0.4-k3s2
node-03   Ready    <none>                 192.168.204.30    Ubuntu 22.04.3 LTS   6.8.0-52-generic     containerd://2.0.4-k3s2
```

## Project Directory Structure

```
.
├── nodejs
│   ├── app
│   │   ├── main.js
│   │   ├── package.json
│   │   ├── README.md
│   │   ├── test.test.js
│   │   └── yarn.lock
│   ├── Dockerfile
│   ├── nodejs-deployment.yaml
│   ├── nodejs-hpa.yaml
│   ├── nodejs-service.yaml
│   └── nodejs-svc-monitor.yaml
├── README.md
├── redis
│   ├── redis-configmap.yaml
│   ├── redis-hpa.yaml
│   ├── redis-main-statefulset.yaml
│   ├── redis-replicas-service.yaml
│   ├── redis-replicas.yaml
│   └── redis-service.yaml
├── redis-exporter
│   ├── redis-exporter.yaml
│   └── redis-svc-monitor.yaml
└── storageclass.yaml
```

## Project Components & Deployment Workflow

### 1. Redis Cluster (Main/Replicas)

Redis is deployed in a master/replica configuration:

- Master: using a StatefulSet for stable network ID and PVC.
- Replicas: using a Deployment with HPA enabled.

Why StatefulSet for Redis Master?
- Ensures stable storage via PVC.
- Keeps a stable hostname (e.g., redis-main-0).

Relevant Files:
- redis-main-statefulset.yaml
- redis-replicas.yaml
- redis-replicas-service.yaml
- redis-service.yaml
- redis-configmap.yaml
- redis-hpa.yaml

### 2. Node.js API Server

Stateless app using Express.js. It uses two Redis clients:

- For write operations, it connects to the Redis master.
- For read operations, it connects to Redis replicas.

The app is instrumented with /metrics endpoint for Prometheus scraping.

Relevant Files:
- nodejs-deployment.yaml
- nodejs-service.yaml
- nodejs-hpa.yaml
- nodejs-svc-monitor.yaml
- Dockerfile

### 3. Redis Exporter (Prometheus-Compatible)

To monitor Redis internals (latency, replication lag, memory, etc.), we used:

- oliver006/redis_exporter:latest image
- Connected to Redis Master via REDIS_ADDR=redis://redis-main:6379

Relevant Files:
- redis-exporter.yaml
- redis-svc-monitor.yaml

### 4. Monitoring Stack: Prometheus & Grafana

Installed using Helm:

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
```

Patches Applied:
To expose services via NodePort:

```
kubectl -n monitoring patch svc prometheus-kube-prometheus-prometheus -p '{"spec": {"type": "NodePort"}}'
kubectl -n monitoring patch svc prometheus-grafana -p '{"spec": {"type": "NodePort"}}'
```

Access Grafana:

```
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

## Metrics Observability

Both Redis and Node.js applications expose metrics, and their corresponding ServiceMonitor objects allow Prometheus to discover them automatically via label selectors.

ServiceMonitor Configuration Highlights:
- selector.matchLabels.app=redis-exporter for Redis.
- selector.matchLabels.app=nodejs for Node.js.
- namespaceSelector.matchNames: ["default"]
- endpoints.path=/metrics, port=metrics

## Final Observations

- Prometheus discovered both redis-service-monitor and nodejs-service-monitor successfully.
- Redis metrics such as redis_memory_used_bytes, redis_commands_total, and redis_connected_clients are tracked.
- Node.js exposes http_requests_total, memory usage, and event loop metrics.
- Autoscaling for both replicas and Node.js backend is enabled via HPA.

This project successfully integrates Infrastructure as Code (IaC), Autoscaling, and Real-Time Monitoring using only Kubernetes-native objects and Helm charts.

Written by: Aymen ZAROUR
CRV Project - Full-stack Kubernetes Automation
