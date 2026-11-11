#!/bin/bash
# Surge more pods at once and stop waiting 4s + 4s on every wave.
kubectl patch deployment image-resizer -n k8smissions --type=merge -p '{"spec":{"minReadySeconds":2,"strategy":{"rollingUpdate":{"maxSurge":"50%","maxUnavailable":"20%"}}}}'
kubectl rollout status deployment/image-resizer -n k8smissions --timeout=120s
