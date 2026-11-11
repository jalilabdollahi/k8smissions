#!/bin/bash
# The app writes to /srv/uploads (see DATA_DIR), the claim is mounted at /var/uploads.
# Mount the claim where the app writes.
kubectl exec -n k8smissions deploy/web-app -- wget -qO- localhost:8080/status; echo
kubectl patch deployment web-app -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/1/mountPath","value":"/srv/uploads"}]'
kubectl rollout status deployment/web-app -n k8smissions --timeout=90s
