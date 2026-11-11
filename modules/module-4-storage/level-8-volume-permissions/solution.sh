#!/bin/bash
kubectl logs -n k8smissions deploy/writer-app --tail=3
kubectl patch deployment writer-app -n k8smissions --type=merge \
  -p '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":10001}}}}}'
kubectl rollout status deployment/writer-app -n k8smissions --timeout=100s
