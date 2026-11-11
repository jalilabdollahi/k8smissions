#!/bin/bash
# Release 2.3 is live; broken.yaml then queues 2.4 into a paused Deployment.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels: {app: frontend}
  template:
    metadata:
      labels: {app: frontend}
    spec:
      containers:
      - name: web
        image: busybox:1.36
        command:
        - sh
        - -c
        - mkdir -p /www && echo "version=$APP_VERSION cart=$FEATURE_NEW_CART" > /www/index.html && exec httpd -f -p 8080 -h /www
        env:
        - {name: APP_VERSION, value: "2.3"}
        - {name: FEATURE_NEW_CART, value: "off"}
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /, port: 8080}
          periodSeconds: 2
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector: {app: frontend}
  ports:
  - port: 80
    targetPort: 8080
YAML
kubectl -n "$NS" rollout status deployment/frontend --timeout=120s
