#!/bin/bash
# Release 3.1 is live on the public images before release 3.2 (broken.yaml) is rolled out.
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storefront
  annotations: {release: "3.1"}
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate: {maxSurge: 1, maxUnavailable: 0}
  selector:
    matchLabels: {app: storefront}
  template:
    metadata:
      labels: {app: storefront}
    spec:
      containers:
      - name: storefront
        image: hashicorp/http-echo:1.0
        args: ["-listen=:8080", "-text=storefront 3.1 - winter catalogue"]
        ports:
        - {containerPort: 8080}
        readinessProbe:
          httpGet: {path: /, port: 8080}
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: storefront
spec:
  selector: {app: storefront}
  ports:
  - {port: 80, targetPort: 8080}
YAML
wait_rollout storefront 120
