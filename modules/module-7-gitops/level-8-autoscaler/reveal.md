## What went wrong

The Cluster Autoscaler uses the `--node-group-auto-discovery` flag to find node groups by cloud provider tag. The flag is set to `asg:tag=wrong-group` — a tag that doesn't match any existing node group. With no discovered groups, the autoscaler has nothing to scale and pending pods stay pending indefinitely.

## Fix

```yaml
args:
- --node-group-auto-discovery=asg:tag=kind-worker
```

## Why this matters

The Cluster Autoscaler monitors for pods in `Pending` state due to `Insufficient cpu/memory` and tries to add nodes to accommodate them. For this to work, it needs to know which node groups it can scale — discovered via cloud provider tags (AWS ASG tags, GCP MIG labels, etc.). The tag must exactly match what the cloud provider has on the node group. On kind (local), there are no real node groups — this level teaches the configuration pattern even though kind can't actually provision new nodes. In production on EKS/GKE/AKS, a misconfigured discovery tag is the #1 cause of 'autoscaler not scaling' incidents.