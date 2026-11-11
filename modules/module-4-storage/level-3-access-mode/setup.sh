#!/bin/bash
# The volume is filled by a one-off Job before the Deployment exists, as in the incident.
kubectl apply -n "$NS" -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: site-content
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: batch/v1
kind: Job
metadata:
  name: seed-content
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: seed
          image: busybox:1.36
          command: ["sh", "-c", "echo 'catalogue-2024-11 release 42' > /site/content"]
          volumeMounts:
            - name: site
              mountPath: /site
      volumes:
        - name: site
          persistentVolumeClaim:
            claimName: site-content
YAML
kubectl wait --for=condition=complete job/seed-content -n "$NS" --timeout=150s
