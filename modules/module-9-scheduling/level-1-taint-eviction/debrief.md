## What was broken

`session-cache` tolerated `maintenance=nightly:NoExecute`, but only for 20 seconds (`tolerationSeconds: 20`). The maintenance window lasts 30 minutes, so every pod that landed on the NVMe node was evicted 20 seconds later and the ReplicaSet started the cycle again.

## The evidence

`kubectl get events` showed `TaintManagerEviction` events naming the session-cache pods, and the pods' ages never passed about 20 seconds. `kubectl describe node` showed the NoExecute taint, and `kubectl get deploy -o yaml` showed that a toleration existed but carried a timer.

## Why Kubernetes behaves this way

NoSchedule only keeps new pods away. NoExecute also evicts pods that are already running. A toleration without `tolerationSeconds` holds forever; with it, the taint manager waits that many seconds and then deletes the pod. The scheduler lets the new pod back in because the toleration matches, so the loop never settles.

## The fix

Drop `tolerationSeconds` (or make it at least as long as the window). Removing the taint would also stop the evictions, but it ends the maintenance protection for everything else, and removing the `nodeSelector` would move the cache away from its NVMe files.

## In production

A short `tolerationSeconds` is a grace period for a pod that can drain or move. A node-local cache cannot move, so it should tolerate the taint for the full window, and the window length should be a documented number next to the taint.

## Commands worth remembering

- `kubectl describe node <node> | grep -A3 Taints`
- `kubectl get events --field-selector reason=TaintManagerEviction`
- `kubectl explain pod.spec.tolerations.tolerationSeconds`
