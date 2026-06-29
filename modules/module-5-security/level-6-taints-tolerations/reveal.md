## What went wrong

The node has the taint `dedicated=gpu:NoSchedule`. A `NoSchedule` taint means the scheduler will not place any pod on that node unless the pod explicitly tolerates it. The pod has no `tolerations` block, so it can't go anywhere.

## Fix

Add a toleration that matches the taint exactly:

```yaml
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  containers:
  - name: app
    image: nginx:latest
```

## Why this matters

Taints and tolerations are the mechanism node operators use to reserve nodes for specific workloads — GPU nodes, high-memory nodes, or nodes with special hardware. A toleration does not *require* the pod to land on that node; it merely *permits* it. Combine tolerations with `nodeAffinity` if you want to both allow and target a specific node type. The three taint effects behave differently: `NoSchedule` stops new pods, `PreferNoSchedule` is a soft hint, and `NoExecute` also evicts running pods.