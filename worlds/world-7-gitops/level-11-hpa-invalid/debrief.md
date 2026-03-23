# Autoscaler Paradox

## What Was Broken
The HPA had `minReplicas: 10` and `maxReplicas: 3`. This is logically invalid — the minimum is higher than the maximum. Kubernetes API server may accept this YAML but the HPA controller enters an error state and cannot reconcile.

## The Fix
Set `minReplicas` ≤ `maxReplicas`. Typical safe production values: `minReplicas: 2` (redundancy), `maxReplicas: 10` (cost cap).

## Why It Matters
HPAs require CPU/memory metrics or custom metrics to scale. Ensure `metrics-server` is installed: `kubectl top pods` should return CPU data. Without metrics, the HPA shows `<unknown>` for TARGETS and never scales.

## Pro Tip
HPA works alongside Cluster Autoscaler. HPA adds pods within the node capacity; CA adds nodes. Set maxReplicas to a value your node pool can actually fit. Check `kubectl describe hpa` — it shows current/desired replicas, metric values, and the last scale event.

## Concepts
HPA, minReplicas, maxReplicas, autoscaling/v2, metrics-server
