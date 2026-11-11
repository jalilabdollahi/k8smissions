#!/bin/bash
kubectl -n k8smissions get secret registry-creds -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d; echo
kubectl -n k8smissions get secret registry-creds -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | sed 's/.*"auth":"\([^"]*\)".*/\1/' | base64 -d | od -c | tail -3
kubectl -n k8smissions create secret docker-registry registry-creds \
  --docker-server=registry.k8smissions.svc.cluster.local:5000 \
  --docker-username=ci-push --docker-password=ship-it-4711 \
  --dry-run=client -o yaml | kubectl -n k8smissions apply -f -
kubectl -n k8smissions create -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: push-
spec:
  pipelineRef:
    name: build-and-push
  taskRunTemplate:
    serviceAccountName: builder
YAML
