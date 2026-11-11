#!/bin/bash
# Readiness takes a hung pod out of the Service in seconds; a tighter liveness restarts it soon after.
kubectl patch deployment ledger-api -n k8smissions --type=json -p '[
  {"op":"add","path":"/spec/template/spec/containers/0/readinessProbe","value":{"httpGet":{"path":"/ready","port":8080},"periodSeconds":1,"timeoutSeconds":1,"failureThreshold":2}},
  {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe","value":{"httpGet":{"path":"/live","port":8080},"periodSeconds":5,"timeoutSeconds":1,"failureThreshold":3}}]'
kubectl rollout status deployment/ledger-api -n k8smissions --timeout=90s
