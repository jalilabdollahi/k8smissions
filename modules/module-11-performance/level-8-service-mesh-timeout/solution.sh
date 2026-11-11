#!/bin/bash
# route.timeout was 3s for a backend that needs up to 9s. Envoy reads its static config at start,
# so the ConfigMap edit only counts after the pod restarts.
kubectl get configmap envoy-config -n k8smissions -o yaml | sed 's/timeout: 3s/timeout: 15s/' | kubectl apply -f -
kubectl rollout restart deployment/invoice-render -n k8smissions
kubectl rollout status deployment/invoice-render -n k8smissions --timeout=90s
