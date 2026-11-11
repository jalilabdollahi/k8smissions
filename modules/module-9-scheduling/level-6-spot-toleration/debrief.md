## What was broken

`render-farm` was pinned with `nodeSelector: lifecycle=spot`. The spot node was reclaimed and tainted `spot-reclaimed:NoSchedule`, so the pods could neither run there nor, because of the selector, anywhere else. The remaining worker carried its own taint, `lifecycle=on-demand:NoSchedule`, which the pods did not tolerate either.

## The evidence

The FailedScheduling event listed two different reasons for the two workers: one node "didn't match Pod's node affinity/selector", the other had "untolerated taint". `kubectl get nodes -L lifecycle` showed the labels, `kubectl describe node` the taints. A reader who fixed only the first sentence of the event still had Pending pods.

## Why Kubernetes behaves this way

Node selection is a pipeline of filters. `nodeSelector` and affinity say where a pod wants to be, taints say who is welcome, and a node must pass every filter. The scheduler reports each node's first failing reason, which is why two blockers show up as two groups in one message.

## The fix

Drop the hard requirement for the spot label and add a toleration matching the on-demand taint (key `lifecycle`, value `on-demand`, effect `NoSchedule`). Tolerating `spot-reclaimed` would be the wrong fix: it lets pods back onto a node that no longer exists as capacity.

## In production

Spot workloads usually prefer spot nodes (`preferredDuringScheduling` affinity) and tolerate the on-demand taint as a fallback, so they flow to on-demand capacity during reclaims and drift back later. Combine with a PodDisruptionBudget so a reclaim does not take the whole farm at once.

## Commands worth remembering

- `kubectl get nodes -L lifecycle`
- `kubectl describe nodes | grep -E "^Name:|^Taints:"`
- `kubectl explain pod.spec.affinity.nodeAffinity`
