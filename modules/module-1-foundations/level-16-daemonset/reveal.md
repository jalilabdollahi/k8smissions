## What went wrong

The control-plane node carries the taint `node-role.kubernetes.io/control-plane:NoSchedule`. This tells the scheduler: 'do not place pods here unless they explicitly tolerate this taint'. The DaemonSet has no tolerations, so its pod is rejected from the only available node.

## Fix

Add tolerations under spec.template.spec in manifest.yaml:

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
- key: node-role.kubernetes.io/master
  operator: Exists
  effect: NoSchedule
```

## Why this matters

DaemonSets are typically used for cluster-wide components like log collectors, monitoring agents, and network plugins. These must run on every node — including control-plane nodes. Without the right tolerations, they silently miss one or more nodes.