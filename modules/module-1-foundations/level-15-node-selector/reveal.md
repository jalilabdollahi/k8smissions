## What went wrong

`nodeSelector: {mission: moon-base}` — no node in the cluster has this label. The scheduler checked every node and found no match, so the pod stays Pending indefinitely.

## Fix

Change the nodeSelector to a label that exists on your nodes:

```yaml
nodeSelector:
  kubernetes.io/os: linux
```

This label is automatically applied to every Linux node by Kubernetes itself.

## Why this matters

nodeSelector is used to restrict a pod to specific nodes — for example nodes with GPUs, high memory, or in a specific availability zone. If the label does not exist, the pod will never run. Always verify labels with `kubectl get nodes --show-labels` before adding a nodeSelector.