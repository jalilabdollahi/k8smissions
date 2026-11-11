#!/bin/bash
# Builds the rollout history: revision 1 (nginx 1.26) and revision 2 (nginx 1.27).
# broken.yaml then applies revision 3, the typo.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe

apply_rev() {  # image, change-cause
cat <<YAML | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  annotations:
    kubernetes.io/change-cause: "$2"
spec:
  replicas: 4
  selector:
    matchLabels: {app: web-app}
  template:
    metadata:
      labels: {app: web-app}
    spec:
      containers:
      - name: nginx
        image: $1
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet: {path: /, port: 80}
          periodSeconds: 2
YAML
}
apply_rev nginx:1.26-alpine "initial release on nginx 1.26"
kubectl -n "$NS" rollout status deployment/web-app --timeout=120s
apply_rev nginx:1.27-alpine "bump to nginx 1.27"
kubectl -n "$NS" rollout status deployment/web-app --timeout=120s
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: web-app
spec:
  selector: {app: web-app}
  ports:
  - port: 80
    targetPort: 80
YAML
