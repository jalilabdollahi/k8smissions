#!/bin/bash
kubectl -n k8smissions logs deploy/hook
kubectl -n k8smissions get configmap hook-binding -o jsonpath='{.data.binding\.json}'
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: hook-binding
data:
  binding.json: |
    {
      "pipeline": "clone-at",
      "params": {
        "revision": "body.head_commit.id",
        "repo-url": "body.repository.clone_url"
      }
    }
YAML
kubectl -n k8smissions rollout restart deployment/hook
kubectl -n k8smissions rollout status deployment/hook --timeout=90s
