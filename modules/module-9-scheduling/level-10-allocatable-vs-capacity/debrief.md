## What was broken

`ledger-batch` asked for 900Mi and each worker had 1400Mi unallocated, so the pod looked like an easy fit. The pod runs under RuntimeClass `sandboxed`, whose `overhead.podFixed` adds 700Mi (the cost of the sandbox itself). The scheduler therefore needed 1600Mi and found no node.

## The evidence

`describe pod` only says `Insufficient memory`. The missing number is on the pod itself: `kubectl get pod -o jsonpath='{.items[0].spec.overhead}'` shows `700Mi`, put there by the RuntimeClass admission plugin at creation time. `describe node` lists per-pod requests but not the overhead of the pod being scheduled, so the arithmetic is easy to get wrong.

## Why Kubernetes behaves this way

Allocatable is not the whole story: what the scheduler subtracts from it is the sum of effective pod requests, and an effective request is the container requests plus pod overhead (and init-container maths). Capacity, allocatable and "what you asked for" are three different numbers. The overhead is also counted by the kubelet when it sizes the pod's cgroup, so it is real memory, not a bookkeeping trick.

## The fix

Security's rule stays: same RuntimeClass, same overhead. The only thing that was inflated was the request, which a profiling run had shown to need 300Mi. Setting it to about 400Mi makes 400 + 700 fit in 1400Mi.

## In production

On real nodes `kube-reserved` and `system-reserved` also push allocatable below capacity, and `kubectl describe node` shows both columns. Do not "fix" the pod by editing the RuntimeClass overhead: that hides cost the node really pays.

## Commands worth remembering

- `kubectl get runtimeclass -o yaml`
- `kubectl get pod <pod> -o jsonpath='{.spec.overhead}'`
- `kubectl describe node <node> | sed -n '/Allocated resources/,/Events/p'`
