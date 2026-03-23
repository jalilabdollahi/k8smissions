# Invisible Metrics

## What Was Broken
The pod exposed port 9090 for metrics but had no Prometheus scrape annotations. The Prometheus kubernetes SD config uses these annotations to discover which pods to scrape and on what port/path.

## The Fix
Add three annotations to the pod (or Deployment template): `prometheus.io/scrape: 'true'`, `prometheus.io/port: '9090'`, `prometheus.io/path: '/metrics'`.

## Why It Matters
The Prometheus annotation convention is widely used but not built into Kubernetes. It's a community standard that prometheus-operator and most Prometheus Helm charts look for by default. If your team uses ServiceMonitor CRDs instead, annotations are not needed — check your monitoring setup.

## Pro Tip
Annotations can be added to running pods with `kubectl annotate`, which avoids pod recreation. But for Deployments, add to spec.template.metadata.annotations so all new pods inherit them.

## Concepts
Prometheus, annotations, service discovery, scrape annotations, metrics port
