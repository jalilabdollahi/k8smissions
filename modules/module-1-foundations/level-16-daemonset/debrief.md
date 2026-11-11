## What was broken

DaemonSet `host-audit` was supposed to run everywhere, but its pod template had no tolerations. The control plane node carries the taint `node-role.kubernetes.io/control-plane:NoSchedule`, so the DaemonSet controller did not create a pod for it. The DaemonSet itself looked healthy: it only counts the nodes it is allowed to use.

## The evidence

`kubectl get ds` printed `DESIRED 2` on a three-node cluster, which is the first clue, because DESIRED counts eligible nodes only. `kubectl get pods -o wide` showed pods on the two workers, none on the control plane, and `kubectl describe node` on that node showed the taint.

## Why Kubernetes behaved this way

DaemonSet pods go through the same taint filter as other pods. The controller computes the nodes that match the node selector and tolerate the node's taints; the others are not counted and no Pending pod appears. Taints are a way for a node to say who is welcome, tolerations a way for a pod to say it accepts the condition.

## The fix

Add a toleration for the control plane taint (`key: node-role.kubernetes.io/control-plane`, `operator: Exists`, `effect: NoSchedule`) to the DaemonSet template. The controller then creates the missing pod and rolls the others, which now match the new template.

## In production

System agents (log collectors, node exporters, security scanners) usually tolerate the control plane taints deliberately; application DaemonSets should not. Removing a taint to make the pod fit changes the rule for every workload. Module 9 covers taints and tolerations in depth.

## Commands worth remembering

- `kubectl describe node <node> | grep -i taint`
- `kubectl get pods -o wide`
- `kubectl get ds -o wide`
