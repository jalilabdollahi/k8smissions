#!/bin/bash
# In-cluster container registry for push levels: Deployment + Service "registry" (port 5000, plain HTTP)
# in $NS, image registry:2.8.3, storage on an emptyDir (lost when the pod restarts).
#   registry.sh                      no authentication
#   registry.sh 'user:BCRYPT_HASH'   basic auth with this htpasswd line (Secret registry-htpasswd)
# Reachable in the cluster as registry:5000 or registry.$NS.svc.cluster.local:5000.
set -e
NS=${NS:-k8smissions}
line=$1
if [ -n "$line" ]; then
  kubectl -n "$NS" create secret generic registry-htpasswd --from-literal=htpasswd="$line" \
    --dry-run=client -o yaml | kubectl -n "$NS" apply -f - >/dev/null
  auth_env='        - {name: REGISTRY_AUTH, value: htpasswd}
        - {name: REGISTRY_AUTH_HTPASSWD_REALM, value: ci-registry}
        - {name: REGISTRY_AUTH_HTPASSWD_PATH, value: /auth/htpasswd}'
  auth_mount='        - {name: auth, mountPath: /auth, readOnly: true}'
  auth_vol='      - name: auth
        secret:
          secretName: registry-htpasswd'
fi
kubectl -n "$NS" apply -f - >/dev/null <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  labels: {app: registry}
spec:
  replicas: 1
  selector:
    matchLabels: {app: registry}
  template:
    metadata:
      labels: {app: registry}
    spec:
      containers:
      - name: registry
        image: registry:2.8.3
        ports:
        - containerPort: 5000
        env:
        - {name: REGISTRY_STORAGE_DELETE_ENABLED, value: "true"}
${auth_env}
        readinessProbe:
          tcpSocket: {port: 5000}
          periodSeconds: 2
        volumeMounts:
        - {name: data, mountPath: /var/lib/registry}
${auth_mount}
      volumes:
      - name: data
        emptyDir: {}
${auth_vol}
---
apiVersion: v1
kind: Service
metadata:
  name: registry
spec:
  selector: {app: registry}
  ports:
  - port: 5000
    targetPort: 5000
YAML
kubectl -n "$NS" rollout status deployment/registry --timeout=120s >/dev/null
