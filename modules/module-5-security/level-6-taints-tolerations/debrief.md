## What was broken

The ETL pool node was fenced with two NoSchedule taints, `dedicated=etl` and `team=data`. `etl-runner` selected the node with `nodeSelector: pool=etl` but tolerated neither taint, so both pods stayed Pending. The `nodeSelector` attracts pods to the node; only tolerations let them in.

## Evidence

`kubectl describe pod` shows the scheduler's `FailedScheduling` message with one untolerated taint. After the first toleration is added the message changes to the other taint: the scheduler reports only the first untolerated taint of each node, which is why a partial fix still leaves pods Pending. `kubectl describe node` lists every taint.

## Why Kubernetes behaved this way

Taints and tolerations are a repel mechanism. A pod must tolerate every NoSchedule taint on a node to be scheduled there. A toleration only permits; it does not attract, so the pool needs both the label with `nodeSelector` (to attract) and the toleration (to be admitted). `web-frontend` stays out because it has neither.

## The fix

Add tolerations matching each taint (`Equal` with key, value, effect) to the `etl-runner` pod template. The rollout creates schedulable pods. Do not remove the taints, which would let any workload onto the pool, and avoid a blanket `operator: Exists`, which tolerates everything.

## In production

Dedicated pools usually combine a taint, a node label, a nodeSelector or affinity and a toleration, often added by a mutating webhook per team. Use `kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints` for an overview.

## Commands worth remembering

- `kubectl describe node <node> | grep -A3 Taints`
- `kubectl get pod <pod> -o jsonpath='{.spec.tolerations}'`
- `kubectl explain pod.spec.tolerations`
