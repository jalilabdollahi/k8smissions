# The Everywhere Pod

## What Was Broken
The DaemonSet had no tolerations. The control-plane node carries a `node-role.kubernetes.io/control-plane:NoSchedule` taint by default. Without a matching toleration, the scheduler refuses to place the pod there.

## The Fix
Add tolerations for both `node-role.kubernetes.io/control-plane` and `node-role.kubernetes.io/master` (the legacy name) using `operator: Exists` so they match regardless of taint value.

## Why It Matters
DaemonSets are meant to run on every node — but that only works if pods can tolerate every node's taints. Infrastructure DaemonSets like log collectors and monitoring agents almost always need control-plane tolerations.

## Pro Tip
Check what taints a node has with `kubectl describe node <name> | grep Taints`. Production clusters often have custom taints per node group (e.g., spot=true:NoSchedule) that DaemonSets must also tolerate.

## Concepts
DaemonSet, tolerations, taints, NoSchedule, control-plane
