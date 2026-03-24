# Autoscaler Blind

## Situation
HPA created but shows "unknown" for CPU metrics. metrics-server not installed.

## Successful Fix
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/... (or bundled metrics-server manifest in level folder)

## What To Validate
kubectl get hpa → TARGETS shows actual CPU%, not <unknown>

## Why It Matters
HPA vs VPA vs KEDA, Metrics API, custom metrics

## Concepts
HPA, metrics-server, resource metrics API, CPU utilization, minReplicas, maxReplicas
