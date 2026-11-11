#!/bin/bash
# Production today is ingest v1: one pod on a single-writer volume (ingest-data, ReadWriteOncePod)
# holding the first sealed batch. broken.yaml then rolls out v2.
kubectl create configmap ingest-src -n "$NS" --from-file=ingest.py=ingest.py \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f - >/dev/null <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ingest-data
  namespace: k8smissions
spec:
  accessModes: ["ReadWriteOncePod"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: ingest
  namespace: k8smissions
spec:
  selector:
    app: ingest
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingest
  namespace: k8smissions
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ingest
  template:
    metadata:
      labels:
        app: ingest
    spec:
      terminationGracePeriodSeconds: 3
      containers:
        - name: ingest
          image: python:3.12-alpine
          command: ["python", "-u", "/src/ingest.py"]
          env:
            - name: INGEST_VERSION
              value: "1"
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            periodSeconds: 2
          volumeMounts:
            - name: src
              mountPath: /src
            - name: data
              mountPath: /data
      volumes:
        - name: src
          configMap:
            name: ingest-src
        - name: data
          persistentVolumeClaim:
            claimName: ingest-data
YAML
kubectl rollout status deployment/ingest -n "$NS" --timeout=150s >/dev/null || exit 1
exit 0
