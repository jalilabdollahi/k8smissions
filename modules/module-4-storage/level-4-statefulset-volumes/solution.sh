#!/bin/bash
# volumeClaimTemplates cannot be added to an existing StatefulSet: recreate it.
kubectl get statefulset postgres-cluster -n k8smissions -o yaml | grep -A3 'volumes:'
kubectl delete statefulset postgres-cluster -n k8smissions --wait=true
kubectl delete pvc pgdata-shared -n k8smissions --wait=true
kubectl apply -n k8smissions -f - <<'YAML'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-cluster
spec:
  serviceName: postgres-cluster
  replicas: 3
  selector:
    matchLabels:
      app: postgres-cluster
  template:
    metadata:
      labels:
        app: postgres-cluster
    spec:
      terminationGracePeriodSeconds: 5
      containers:
        - name: postgres
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              f=/var/lib/pgdata/node-id
              [ -f "$f" ] || hostname > "$f"
              if [ "$(cat "$f")" != "$(hostname)" ]; then
                echo "FATAL: data directory belongs to $(cat "$f"), refusing to start as $(hostname)"
                exit 1
              fi
              echo "member $(hostname) ready, data directory is mine"
              touch /tmp/ready
              trap 'exit 0' TERM
              while :; do sleep 1; done
          readinessProbe:
            exec:
              command: ["test", "-f", "/tmp/ready"]
            periodSeconds: 2
          volumeMounts:
            - name: pgdata
              mountPath: /var/lib/pgdata
  volumeClaimTemplates:
    - metadata:
        name: pgdata
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
YAML
kubectl rollout status statefulset/postgres-cluster -n k8smissions --timeout=120s
