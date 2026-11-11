## What was broken

`ledger-api` was meant to run only on the restricted-data node, but its affinity was `preferredDuringSchedulingIgnoredDuringExecution`. That is a score: the scheduler adds weight to matching nodes and still places pods elsewhere. Here a topology spread constraint kept the replicas even across the two workers, so half of them landed on the unlabelled node.

## Evidence

`kubectl get pods -o wide` against `kubectl get nodes -L data-class` shows pods on a node without the label. The Deployment YAML shows `preferred...` instead of `required...`.

## Why Kubernetes behaved this way

Node affinity has two modes. `required...` filters nodes: a pod that fits nowhere stays Pending. `preferred...` only adds to the score. Both end in `IgnoredDuringExecution`: affinity is evaluated at scheduling time only, so changing a rule never evicts a running pod. Pods move because editing the pod template makes the Deployment create new pods, which are scheduled under the new rule.

## The fix

Make the rule required (or use a `nodeSelector` for the same effect) and let the rollout replace the pods. Labelling the other worker as well would satisfy a checker but breaks the compliance meaning of the label.

## In production

Pair the hard rule with a taint on the restricted node and a matching toleration so that other workloads stay away too (module 9 and the next level cover taints). Watch capacity: a required rule with too few matching nodes leaves pods Pending.

## Commands worth remembering

- `kubectl get nodes -L data-class`
- `kubectl get pods -o wide`
- `kubectl explain pod.spec.affinity.nodeAffinity`
