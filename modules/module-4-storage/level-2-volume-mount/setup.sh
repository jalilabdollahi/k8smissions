#!/bin/bash
# Puts the shared upload service source into a ConfigMap the Deployment runs.
kubectl create configmap uploader-src -n "$NS" --from-file=app.py=../_fixtures/uploader.py \
  --dry-run=client -o yaml | kubectl apply -f -
