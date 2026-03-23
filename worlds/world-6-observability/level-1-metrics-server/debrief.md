# Flying Blind

## Situation
Team complains "kubectl top pods" returns error: "metrics not available yet". metrics-server not installed. HPA also broken because of this.

## Successful Fix
Apply metrics-server manifest (bundled in level folder) Wait for it to become Ready, verify kubectl top pods works

## What To Validate
kubectl top pods -n k8smissions returns CPU/Memory values

## Why It Matters
Review how the fix changed the cluster behavior for Flying Blind.

## Concepts
Metrics API, metrics-server, Resource Metrics Pipeline, Custom Metrics API, Prometheus Adapter
