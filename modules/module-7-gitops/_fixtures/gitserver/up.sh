#!/bin/bash
# Start the in-cluster Git server (namespace gitops-git) and wait until it answers.
# Idempotent. Usage: up.sh
set -e
d=$(cd "$(dirname "$0")" && pwd)
kubectl get ns gitops-git >/dev/null 2>&1 || kubectl create namespace gitops-git
kubectl label ns gitops-git k8smissions/managed=true --overwrite >/dev/null
kubectl -n gitops-git create configmap gitserver-code --from-file=server.py="$d/server.py" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n gitops-git label configmap gitserver-code k8smissions/managed=true --overwrite >/dev/null
kubectl apply -f "$d/gitserver.yaml" >/dev/null
kubectl -n gitops-git rollout status deploy/gitserver --timeout=180s >/dev/null
