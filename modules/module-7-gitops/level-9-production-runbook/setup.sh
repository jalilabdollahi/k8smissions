#!/bin/bash
# schema stub, the Git repo and the Application
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" create configmap schema-stub --from-file=stub.py
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: schema-db
spec:
  replicas: 1
  selector:
    matchLabels: {app: schema-db}
  template:
    metadata:
      labels: {app: schema-db}
    spec:
      containers:
      - name: stub
        image: python:3.12-alpine
        command: ["python", "/code/stub.py"]
        volumeMounts:
        - {name: code, mountPath: /code}
        readinessProbe:
          httpGet: {path: /version, port: 8080}
          periodSeconds: 2
      volumes:
      - name: code
        configMap: {name: schema-stub}
---
apiVersion: v1
kind: Service
metadata:
  name: schema-db
spec:
  selector: {app: schema-db}
  ports:
  - port: 80
    targetPort: 8080
YAML
kubectl -n "$NS" label deploy,svc,cm -l '!k8smissions/managed' k8smissions/managed=true --overwrite >/dev/null 2>&1
kubectl -n "$NS" rollout status deploy/schema-db --timeout=120s >/dev/null
../_fixtures/gitserver/seed.sh ledger repo "ledger-api v3 with schema migration hook"
../_fixtures/argo-app.sh app.yaml
../_fixtures/wait-ready.sh probe
