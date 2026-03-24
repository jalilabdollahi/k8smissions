# HPA Can't Scale

## What Was Broken
HPA requires the metrics-server to read pod CPU/memory metrics via the Metrics API. Without metrics-server, HPA shows unknown and can't make scaling decisions.

## The Fix
Install metrics-server. For local/dev clusters, you may need --kubelet-insecure-tls flag in the metrics-server deployment args.

## Why It Matters
Custom and external metrics for HPA: install Prometheus Adapter to expose Prometheus metrics to the Kubernetes Metrics API. Then HPA can scale on request rate, queue depth, error rate — any Prometheus metric.

## Pro Tip
HPA scale-down behavior: add stabilizationWindowSeconds: 300 to prevent rapid scale-down (flapping). The example in solution.yaml adds this recommended production behavior.

## Concepts
HPA, metrics-server, CPU utilization, unknown metrics, Metrics API
