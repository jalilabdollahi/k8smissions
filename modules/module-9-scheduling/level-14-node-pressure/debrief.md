## What was broken

Each `log-compactor` pod writes about 120Mi into its container filesystem and was evicted a few seconds later. The Deployment says nothing about storage. The limit of 50Mi came from a LimitRange in the namespace, which fills in a default `ephemeral-storage` limit for any container that has none.

## The evidence

`kubectl get events` showed `Evicted: Pod ephemeral local storage usage exceeds the total limit of containers 50Mi`. The Deployment's YAML has no 50Mi anywhere, so the next place to look is the live pod (`get pod -o yaml` has `resources.limits.ephemeral-storage: 50Mi`) and then the LimitRange that admitted it. The nodes were healthy, which rules out real node pressure.

## Why Kubernetes behaves this way

Ephemeral storage is accounted per pod: the container's writable layer, its logs and any emptyDir. The kubelet's eviction manager compares each pod's usage with its limit every few seconds and evicts the pod when it is exceeded, with a Failed pod object left behind as evidence. The scheduler never sees this usage at all, only requests, so the pod schedules happily and dies later.

## The fix

Set an explicit limit (and a matching request, so the scheduler reserves the space) larger than what the job writes. Editing the LimitRange default also works for future pods, but existing ones are not touched, and a bigger default affects every other workload in the namespace.

## In production

LimitRange defaults are invisible in a Deployment, which is why they cause confusing incidents. Prefer explicit limits, write scratch data to an `emptyDir` with `sizeLimit`, and clean up `Failed` Evicted pods because they accumulate.

## Commands worth remembering

- `kubectl get events --field-selector reason=Evicted`
- `kubectl get limitrange -o yaml`
- `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].resources}'`
