#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

echo " Déploiement du projet CRV-IaC en cours..."

### 1. Création du StorageClass (si ce n'est pas déjà fait)
echo " Création de la StorageClass local-path..."
kubectl apply -f storageclass.yaml

### 2. Déploiement de Redis (master + replicas + services + autoscaling)
echo " Déploiement de Redis (Master et Replicas)..."
kubectl apply -f redis/redis-configmap.yaml
kubectl apply -f redis/redis-service.yaml
kubectl apply -f redis/redis-main-statefulset.yaml
kubectl apply -f redis/redis-replicas-service.yaml
kubectl apply -f redis/redis-replicas.yaml
kubectl apply -f redis/redis-hpa.yaml

### 3. Déploiement de l'application Node.js
echo " Déploiement de l'application Node.js..."
kubectl apply -f nodejs/nodejs-service.yaml
kubectl apply -f nodejs/nodejs-deployment.yaml
kubectl apply -f nodejs/nodejs-hpa.yaml

### 4. Configuration du monitoring (Redis Exporter + ServiceMonitor)
echo " Déploiement du Redis Exporter et ses métriques..."
kubectl apply -f redis-exporter/redis-exporter.yaml
kubectl apply -f redis-exporter/redis-svc-monitor.yaml

echo " Ajout du ServiceMonitor pour l'application Node.js..."
kubectl apply -f nodejs/nodejs-svc-monitor.yaml

### 5. Installation de Prometheus & Grafana via Helm
echo " Installation de la stack Prometheus + Grafana via Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update
kubectl create namespace monitoring || true
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring || true

### 6. Patch pour exposer Grafana et Prometheus (NodePort)
echo " Patch des services Grafana et Prometheus pour accès externe..."
kubectl -n monitoring patch svc prometheus-kube-prometheus-prometheus -p '{"spec": {"type": "NodePort"}}'
kubectl -n monitoring patch svc prometheus-grafana -p '{"spec": {"type": "NodePort"}}'

### 7. Fin du déploiement
echo " Déploiement terminé avec succès !"

GRAFANA_PWD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "🔐 Mot de passe Grafana : $GRAFANA_PWD"

echo -e "\n Accès Grafana possible via : http://<NodeIP>:<NodePort>"
