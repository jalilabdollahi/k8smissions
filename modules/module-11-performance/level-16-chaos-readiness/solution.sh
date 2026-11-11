#!/bin/bash
# The anti-affinity selector matches a label no pod carries; fix it, then restart so the pods are placed again.
kubectl patch deployment checkout-api -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/affinity/podAntiAffinity/requiredDuringSchedulingIgnoredDuringExecution/0/labelSelector","value":{"matchLabels":{"app.kubernetes.io/name":"checkout-api"}}}]'
kubectl rollout status deployment/checkout-api -n k8smissions --timeout=120s
