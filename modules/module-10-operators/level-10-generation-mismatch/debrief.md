## What was broken

`inventory-operator` stamped a new `lastSync` timestamp into `Inventory` status on every two-second pass, and computed `observedGeneration` as "previous value + 1". The first made every pass a real write; the second meant the field never matched `metadata.generation`, so nobody could tell whether the operator had seen the latest spec.

## The evidence

Sampling `metadata.resourceVersion` of an object nobody touches showed it changing every few seconds. `status.observedGeneration` kept growing past `metadata.generation`. The operator logs one `reconciled` line per object per pass, which confirms there is no "nothing to do" path.

## Why Kubernetes behaved this way

A write that changes any byte of the object bumps `resourceVersion`. An update that changes nothing is dropped by the API server, which is why the fix is "compute the desired status, compare, and only then patch". `metadata.generation` is maintained by the API server and increases only when `spec` changes; with the status subresource enabled, status writes never touch it. `observedGeneration` is the controller's receipt: "I have processed generation N".

The tempting shortcut, "skip the whole pass when observedGeneration == generation", stops the writes but also stops the operator from noticing that a child ConfigMap was deleted or edited, because nothing in the CR changed. Controllers have to be level-triggered: observe the real state every time, act on the difference, and make the write of status the only guarded step.

## In production

Real controllers watch instead of polling, use predicates such as `GenerationChangedPredicate` for the CR, and also watch the objects they own, so drift in a child triggers a pass. Frequent status writes cost etcd revisions and wake every watcher of the object.

## Worth remembering

- `kubectl get <cr> -o jsonpath='{.metadata.generation} {.status.observedGeneration}'`
- `kubectl get <cr> -w -o custom-columns=NAME:.metadata.name,RV:.metadata.resourceVersion`
- `kubectl explain <cr>.status` shows what the schema keeps.
