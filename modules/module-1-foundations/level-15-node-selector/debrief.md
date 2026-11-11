## What was broken

Pod `cache-warm` had `nodeSelector: {disktype: ssd}`. The infrastructure team labelled the fast worker `disk=ssd` (and the slow one `disk=hdd`). The key in the pod and the key on the node did not match, so no node satisfied the selector and the pod could not be scheduled.

## The evidence

`kubectl get pod` showed `Pending` with no restarts and no logs. `kubectl describe pod` ended with a `FailedScheduling` event saying the nodes did not match the pod's node affinity or selector. `kubectl get nodes --show-labels` showed which labels existed: `disk=ssd`, `disk=hdd`, and nothing called `disktype`.

## Why Kubernetes behaved this way

The scheduler filters nodes by every `nodeSelector` pair as an exact label match. A mismatch is not an error: the pod simply waits, and is re-evaluated whenever nodes or labels change. The control plane node is excluded as well, by its taint. A running pod's `nodeSelector` cannot be changed, so the pod has to be recreated.

## The fix

Recreate the pod with `nodeSelector: {disk: ssd}`. Labelling the SSD node with an extra `disktype=ssd` would also work, as long as it is the right node. Labelling the HDD node to make the pod schedule is wrong: it would run, on the wrong disk.

## In production

A Deployment makes this cheaper to fix (edit the template and it rolls). Agree on label keys across teams and document them; node labels such as `disk` or `zone` are conventions the cluster cannot check. For soft preferences use node affinity, which module 9 covers.

## Commands worth remembering

- `kubectl get nodes --show-labels` / `-L disk`
- `kubectl describe pod <pod>` (Events)
- `kubectl get pod <pod> -o wide` (which node)
