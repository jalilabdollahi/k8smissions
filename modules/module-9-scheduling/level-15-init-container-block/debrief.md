## What was broken

`payments-migrator` could never be scheduled. Its app container wanted 100Mi, but its `db-migrate` init container requested 1500Mi, while each worker had only about 1000Mi unreserved.

## The evidence

`FailedScheduling: Insufficient memory` on both workers, even though the visible app request was tiny. Someone had already lowered the app container's request, with no effect, which is the clue that the number the scheduler uses is not the sum of the app containers. Reading `spec.initContainers[0].resources` showed the 1500Mi.

## Why Kubernetes behaves this way

Init containers run sequentially, each to completion, before the app containers start. Since they never run at the same time as the app, the scheduler takes the effective request as the maximum of the largest init container and the sum of the app containers (per resource). A fat init container therefore blocks scheduling although it only lives for seconds.

## The fix

Shrink the init container's request to something the node can give, in line with what the migration actually uses: about 550Mi in memory. A request of 700Mi leaves headroom, and the limit stays well above the real usage. Cutting the limit as well would trade a scheduling failure for an OOMKill in the init container, and the migration would never finish.

## In production

Compare `kubectl top` (or Prometheus) with requests for init containers too. Init containers that restart (`restartPolicy: Always` sidecars) are counted differently, because they keep running with the app.

## Commands worth remembering

- `kubectl get pod <pod> -o jsonpath='{.spec.initContainers[*].resources}'`
- `kubectl describe node <node> | grep -A8 'Allocated resources'`
- `kubectl logs <pod> -c <init-container>`
