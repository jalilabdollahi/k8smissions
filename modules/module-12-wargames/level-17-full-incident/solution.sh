#!/bin/bash
NS=k8smissions
# 1. The failed migration (and its pod) uses the PVC; remove it, then the PVC with the missing StorageClass.
kubectl -n $NS delete job db-migrate --wait=true
kubectl -n $NS delete pvc shop-data --wait=true
kubectl -n $NS apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shop-data
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources:
    requests: {storage: 1Gi}
EOF
# 2. Re-run the migration with a schema the release knows (v7).
kubectl -n $NS apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: busybox:1.36
        command: ["sh", "/src/migrate.sh", "--schema=v7"]
        volumeMounts:
        - {name: data, mountPath: /data}
        - {name: src, mountPath: /src}
      volumes:
      - name: data
        persistentVolumeClaim: {claimName: shop-data}
      - name: src
        configMap: {name: shop-src}
EOF
# 3. The Deployment's ServiceAccount does not exist, so no pod was ever created.
kubectl -n $NS create serviceaccount shop-runner
# 4. The Ingress names a port the Service does not have (the Service port is called web).
kubectl -n $NS patch ingress shop --type=json -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port","value":{"name":"web"}}]'
kubectl -n $NS wait --for=condition=complete job/db-migrate --timeout=120s
kubectl -n $NS rollout status deploy/shop-web --timeout=150s
